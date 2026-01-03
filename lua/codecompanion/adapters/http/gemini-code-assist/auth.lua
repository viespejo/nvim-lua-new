local curl = require("plenary.curl")
local config = require("codecompanion.config")

local M = {}

-- flag to indicate if we're in the process of authenticating
local is_authenticating = false

-- Configuration constants
-- These credentials mimic the Google Cloud Code extension to access the specific API
local CONFIG = {
  CLIENT_ID = vim.env.GEMINI_CLIENT_ID or "681255809395-oo8ft2oprdrnp9e3aqf6av3hmdib135j.apps.googleusercontent.com",
  CLIENT_SECRET = vim.env.GEMINI_CLIENT_SECRET or "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",
  AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth",
  TOKEN_URL = "https://oauth2.googleapis.com/token",
  TOKEN_FILE = vim.fs.joinpath(vim.fn.stdpath("data"), "/gemini_code_assist_token.json"),
}

---Save the token response to disk
---@param data table
---@return boolean
local function save_token(data)
  local file = io.open(CONFIG.TOKEN_FILE, "w")
  if file then
    file:write(vim.json.encode(data))
    file:close()
    return true
  end
  return false
end

---Load the refresh token from disk
---@return string|nil
function M.load_token()
  local file = io.open(CONFIG.TOKEN_FILE, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local ok, data = pcall(vim.json.decode, content)
    if ok and data.refresh_token then
      return data.refresh_token
    end
  end
  return nil
end

---Exchange the authorization code for access/refresh tokens
---@param code string
---@param redirect_uri string
local function exchange_code(code, redirect_uri)
  local status, response = pcall(curl.post, CONFIG.TOKEN_URL, {
    insecure = config.adapters.http.opts.allow_insecure,
    proxy = config.adapters.http.opts.proxy,
    body = {
      client_id = CONFIG.CLIENT_ID,
      client_secret = CONFIG.CLIENT_SECRET,
      code = code,
      grant_type = "authorization_code",
      redirect_uri = redirect_uri,
    },
    timeout = 10000,
  })

  if not status then
    vim.notify("Gemini: error in curl request: " .. tostring(response), vim.log.levels.ERROR)
    return nil
  end

  if response.status == 200 then
    local ok, data = pcall(vim.json.decode, response.body)

    if not ok then
      vim.notify("Gemini: error parsing token response: " .. tostring(data), vim.log.levels.ERROR)
      return nil
    end

    if save_token(data) then
      vim.notify("Gemini: token saved successfully!", vim.log.levels.INFO)
      return data
    end
  else
    vim.notify("Gemini: error exchanging code: " .. tostring(response.body), vim.log.levels.ERROR)
  end
end

---Start the OAuth2 PKCE-like flow with a local server
function M.authenticate()
  if is_authenticating then
    vim.notify("⚠️ Gemini: Authentication process already in progress.", vim.log.levels.WARN)
    return
  end
  is_authenticating = true

  -- timeout to reset the flag in case something goes wrong
  -- (e.g. 60s, user doesn't complete the auth in time)
  vim.defer_fn(function()
    is_authenticating = false
  end, 60000)

  local uv = vim.uv or vim.loop
  local server = uv.new_tcp()
  local host = "127.0.0.1"
  local port = 0 -- Let OS assign a free port

  server:bind(host, port)

  -- Retrieve assigned port
  local address = server:getsockname()
  port = address.port
  local redirect_uri = string.format("http://%s:%d", host, port)

  local state_code = math.random(100000, 999999) -- simple CSRF protection

  -- init the server
  server:listen(128, function(err)
    assert(not err, err)
    local client = uv.new_tcp()
    server:accept(client)

    client:read_start(function(read_err, chunk)
      if chunk then
        local code = chunk:match("code=([^& ]+)")
        local state = chunk:match("state=([^& ]+)")

        local response_body
        if code and tonumber(state) == state_code then
          response_body =
            "<h1>Authentication Successful</h1><p>You can close this window and return to Neovim.</p><script>window.close()</script>"
          -- schedule the token exchange out of the uv loop
          vim.schedule(function()
            exchange_code(code, redirect_uri)
            is_authenticating = false
          end)
        else
          response_body = "<h1>Error</h1><p>Could not obtain code or invalid state.</p>"
          is_authenticating = false
        end

        local response = "HTTP/1.1 200 OK\r\n"
          .. "Content-Type: text/html\r\n"
          .. "Content-Length: "
          .. #response_body
          .. "\r\n"
          .. "Connection: close\r\n\r\n"
          .. response_body

        client:write(response, function()
          client:shutdown()
          client:close()
          server:close() -- close the server after handling one request
        end)
      end
    end)
  end)

  -- build the auth URL
  local url = string.format(
    "%s?client_id=%s&redirect_uri=%s&response_type=code&scope=https://www.googleapis.com/auth/cloud-platform&access_type=offline&prompt=consent&state=%s",
    CONFIG.AUTH_URL,
    CONFIG.CLIENT_ID,
    vim.uri_encode(redirect_uri),
    state_code
  )

  vim.notify("Gemini: Opening browser for authentication...", vim.log.levels.INFO)
  vim.ui.open(url)
end

return M
