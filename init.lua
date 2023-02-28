-- DO NOT EDIT THIS FILE DIRECTLY
-- This is a file generated from a literate programing source file located at
-- https://github.com/zzamboni/dot-hammerspoon/blob/master/init.org.
-- You should make any changes there and regenerate it from Emacs org-mode using C-c C-v t

hs.logger.defaultLogLevel="info"

hyper       = {"cmd","alt","ctrl"}
shift_hyper = {"cmd","alt","ctrl","shift"}
ctrl_cmd    = {"cmd","ctrl"}

col = hs.drawing.color.x11

work_logo = hs.image.imageFromPath(hs.configdir .. "/files/work_logo_2x.png")

hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.zzspoons = {
  url = "https://github.com/zzamboni/zzSpoons",
  desc = "zzamboni's spoon repository",
}

spoon.SpoonInstall.use_syncinstall = true

Install=spoon.SpoonInstall

-- Install:andUse("BetterTouchTool", { loglevel = 'debug' })
-- BTT = spoon.BetterTouchTool

-- Returns the bundle ID of an application, given its path.
function appID(app)
  if hs.application.infoForBundlePath(app) then
    return hs.application.infoForBundlePath(app)['CFBundleIdentifier']
  end
end

-- Returns a function that takes a URL and opens it in the given Chrome profile
-- Note: the value of `profile` must be the name of the profile directory under
-- ~/Library/Application Support/Google/Chrome/
function chromeProfile(profile)
  return function(url)
    hs.task.new("/usr/bin/open", nil, { "-n",
                                        "-a", "Google Chrome",
                                        "--args",
                                        "--profile-directory="..profile,
                                        url }):start()
  end
end

-- Define the IDs of the various applications used to open URLs
chromeBrowser  = appID('/Applications/Google Chrome.app')
braveBrowser   = appID('/Applications/Brave Browser.app')
safariBrowser  = appID('/Applications/Safari.app')
firefoxBrowser = appID('/Applications/Firefox.app')
teamsApp       = appID('/Applications/Microsoft Teams.app')
quipApp        = appID('/Applications/Quip.app')
chimeApp       = appID('/Applications/Amazon Chime.app')

-- Define my default browsers for various purposes
browsers = {
  default    = braveBrowser,
  awsConsole = firefoxBrowser,
  work       = chromeProfile("Default"),
  customer1  = chromeProfile("Profile 1")
}

-- Read URL patterns from text files
URLfiles = {
  work = "local/work_urls.txt",
  customer1 = "local/customer1_urls.txt"
}

Install:andUse("URLDispatcher",
               {
                 config = {
                   default_handler = browsers.default,
                   url_patterns = {
                     -- URLs that get redirected to applications
                     { "https://quip%-amazon%.com/"      , quipApp },
                     { "https://teams%.microsoft%.com/"  , teamsApp },
                     -- I haven't figured out how to send Chime URLs directly to
                     -- the app in a way that it understands them, so for now we
                     -- send them to browsers.work, which in turn redirects to the
                     -- app.
                     { "https://chime%.aws/"             , browsers.work },
                     -- Customer-specific URLs open in their own Chrome profile
                     { URLfiles.customer1                , browsers.customer1 },
                     -- Amazon console URLs open by default in Firefox. This is after customer1
                     -- URLs because I have patterns for that customer's accounts to open in its
                     -- corresponding profile.
                     { ".*%.console%.aws%.amazon%.com/.*", browsers.awsConsole },
                     -- Work-related URLs open in the default Chrome profile
                     { URLfiles.work                     , browsers.work },
                   },
                   url_redir_decoders = {
                     -- URLs opened from within MS Teams are normally sent
                     -- through a redirect which messes the matching, so we
                     -- extract the final URL before dispatching it. The final
                     -- URL is passed as parameter "url" to the redirect URL,
                     -- which makes it easy to extract it using a function-based
                     -- decoder.
                     { "MS Teams links", function(_, _, params) return params.url end, nil, true, "Microsoft Teams" }
                   }
                 },
                 start = true,
                 loglevel = 'debug'
               }
)

Install:andUse("WindowHalfsAndThirds",
               {
                 config = {
                   use_frame_correctness = true
                 },
                 hotkeys = 'default',
--                 loglevel = 'debug'
               }
)

myGrid = { w = 6, h = 4 }
Install:andUse("WindowGrid",
               {
                 config = { gridGeometries =
                              { { myGrid.w .."x" .. myGrid.h } } },
                 hotkeys = {show_grid = {hyper, "g"}},
                 start = true
               }
)

Install:andUse("WindowScreenLeftAndRight",
               {
                 config = {
                   animationDuration = 0
                 },
                 hotkeys = 'default',
--                 loglevel = 'debug'
               }
)

Install:andUse("ToggleScreenRotation",
               {
                 hotkeys = { first = {hyper, "f15"} }
               }
)

Install:andUse("UniversalArchive",
               {
                 config = {
                   evernote_archive_notebook = ".Archive",
                   archive_notifications = false,
                   outlook_archive_folder = "Archive (dzamboni@amazon.com)"
                 },
                 hotkeys = { archive = { { "ctrl", "cmd" }, "a" } }
               }
)

function chrome_item(n)
  return { apptype = "chromeapp", itemname = n }
end

function OF_register_additional_apps(s)
  s:registerApplication("Swisscom Collab", chrome_item("tab"))
  s:registerApplication("Swisscom Wiki", chrome_item("wiki page"))
  s:registerApplication("Swisscom Jira", chrome_item("issue"))
  s:registerApplication("Brave Browser", chrome_item("page"))
end

Install:andUse("SendToOmniFocus",
               {
                 disable = true,
                 config = {
                   quickentrydialog = false,
                   notifications = false
                 },
                 hotkeys = {
                   send_to_omnifocus = { hyper, "t" }
                 },
                 fn = OF_register_additional_apps,
               }
)

org_capture_path = os.getenv("HOME").."/.hammerspoon/files/org-capture.lua"
script_file = io.open(org_capture_path, "w")
script_file:write([[local win = hs.window.frontmostWindow()
local o,s,t,r = hs.execute("~/.emacs.d/bin/org-capture", true)
if not s then
  print("Error when running org-capture: "..o.."\n")
end
win:focus()
]])
script_file:close()

hs.hotkey.bindSpec({hyper, "t"},
  function ()
    hs.task.new("/bin/bash", nil, { "-l", "-c", "/usr/local/bin/hs "..org_capture_path }):start()
  end
)

Install:andUse("EvernoteOpenAndTag",
               {
                 disable = true,
                 hotkeys = {
                   open_note = { hyper, "o" },
                   ["open_and_tag-+work"] = { hyper, "w" },
                   ["open_and_tag-+personal"] = { hyper, "p" },
                   ["tag-@zzdone"] = { hyper, "z" }
                 }
               }
)

Install:andUse("TextClipboardHistory",
               {
                 disable = true,
                 config = {
                   show_in_menubar = false,
                 },
                 hotkeys = {
                   toggle_clipboard = { { "cmd", "shift" }, "v" } },
                 start = true,
               }
)

Install:andUse("Hammer",
               {
                 repo = 'zzspoons',
                 config = { auto_reload_config = false },
                 hotkeys = {
                   config_reload = {hyper, "r"},
                   toggle_console = {hyper, "y"}
                 },
--                 fn = BTT_restart_Hammerspoon,
                 start = true
               }
)

Install:andUse("Caffeine", {
                 start = true,
                 hotkeys = {
                   toggle = { hyper, "1" }
                 },
--                 fn = BTT_caffeine_widget,
})

Install:andUse("MenubarFlag",
               {
                 config = {
                   colors = {
                     ["U.S."] = { },
                     Spanish = {col.green, col.white, col.red},
                     ["Latin American"] = {col.green, col.white, col.red},
                     German = {col.black, col.red, col.yellow},
                   }
                 },
                 start = true
               }
)

Install:andUse("MouseCircle",
               {
                 disable = true,
                 config = {
                   color = hs.drawing.color.x11.rebeccapurple
                 },
                 hotkeys = {
                   show = { hyper, "m" }
                 }
               }
)

Install:andUse("ColorPicker",
               {
                 disable = true,
                 hotkeys = {
                   show = { hyper, "z" }
                 },
                 config = {
                   show_in_menubar = false,
                 },
                 start = true,
               }
)

Install:andUse("BrewInfo",
               {
                 config = {
                   brew_info_style = {
                     textFont = "Inconsolata",
                     textSize = 14,
                     radius = 10 }
                 },
                 hotkeys = {
                   -- brew info
                   show_brew_info = {hyper, "b"},
                   open_brew_url = {shift_hyper, "b"},
                   -- brew cask info - not needed anymore, the above now do both
                   -- show_brew_cask_info = {shift_hyper, "c"},
                   -- open_brew_cask_url = {hyper, "c"},
                 }
               }
)

Install:andUse("TimeMachineProgress",
               {
                 start = true
               }
)

Install:andUse("TurboBoost",
               {
                 disable = true,
                 config = {
                   disable_on_start = true
                 },
                 hotkeys = {
                   toggle = { hyper, "0" }
                 },
                 start = true,
                 --                   loglevel = 'debug'
               }
)

Install:andUse("EjectMenu", {
                 config = {
                   eject_on_lid_close = false,
                   eject_on_sleep = false,
                   show_in_menubar = true,
                   notify = true,
                 },
                 hotkeys = { ejectAll = { hyper, "=" } },
                 start = true,
--                 loglevel = 'debug'
})

Install:andUse("HeadphoneAutoPause",
               {
                 start = true,
                 disable = true,
               }
)

Install:andUse("Seal",
               {
                 hotkeys = { show = { {"alt"}, "space" } },
                 fn = function(s)
                   s:loadPlugins({"apps", "calc", "safari_bookmarks",
                                  "screencapture", "useractions"})
                   s.plugins.safari_bookmarks.always_open_with_safari = false
                   s.plugins.useractions.actions =
                     {
                         ["Hammerspoon docs webpage"] = {
                           url = "http://hammerspoon.org/docs/",
                           icon = hs.image.imageFromName(hs.image.systemImageNames.ApplicationIcon),
                         },
                         ["Leave corpnet"] = {
                           fn = function()
                             spoon.WiFiTransitions:processTransition('foo', 'corpnet01')
                           end,
                           icon = work_logo,
                         },
                         ["Arrive in corpnet"] = {
                           fn = function()
                             spoon.WiFiTransitions:processTransition('corpnet01', 'foo')
                           end,
                           icon = work_logo,
                         },
                         ["Translate using Leo"] = {
                           url = "http://dict.leo.org/englisch-deutsch/${query}",
                           icon = 'favicon',
                           keyword = "leo",
                         }
                     }
                   s:refreshAllCommands()
                 end,
                 start = true,
               }
)

function reconfigSpotifyProxy(proxy)
  local spotify = hs.appfinder.appFromName("Spotify")
  local lastapp = nil
  if spotify then
    lastapp = hs.application.frontmostApplication()
    spotify:kill()
    hs.timer.usleep(40000)
  end
  -- I use CFEngine to reconfigure the Spotify preferences
  cmd = string.format(
    "/usr/local/bin/cf-agent -K -f %s/files/spotify-proxymode.cf%s",
    hs.configdir, (proxy and " -DPROXY" or " -DNOPROXY"))
  output, status, t, rc = hs.execute(cmd)
  if spotify and lastapp then
    hs.timer.doAfter(
      3,
      function()
        if not hs.application.launchOrFocus("Spotify") then
          hs.notify.show("Error launching Spotify", "", "")
        end
        if lastapp then
          hs.timer.doAfter(0.5, hs.fnutils.partial(lastapp.activate, lastapp))
        end
    end)
  end
end

function reconfigAdiumProxy(proxy)
  app = hs.application.find("Adium")
  if app and app:isRunning() then
    local script = string.format([[
  tell application "Adium"
    repeat with a in accounts
      if (enabled of a) is true then
        set proxy enabled of a to %s
      end if
    end repeat
    go offline
    go online
  end tell
  ]], hs.inspect(proxy))
    hs.osascript.applescript(script)
  end
end

function stopApp(name)
  app = hs.application.get(name)
  if app and app:isRunning() then
    app:kill()
  end
end

function forceKillProcess(name)
  hs.execute("pkill " .. name)
end

function startApp(name)
  hs.application.open(name)
end

Install:andUse("WiFiTransitions",
               {
                 config = {
                   actions = {
                     -- { -- Test action just to see the SSID transitions
                     --    fn = function(_, _, prev_ssid, new_ssid)
                     --       hs.notify.show("SSID change",
                     --          string.format("From '%s' to '%s'",
                     --          prev_ssid, new_ssid), "")
                     --    end
                     -- },
                     { -- Enable proxy config when joining corp network
                       to = "corpnet01",
                       fn = {hs.fnutils.partial(reconfigSpotifyProxy, true),
                             hs.fnutils.partial(reconfigAdiumProxy, true),
                             hs.fnutils.partial(forceKillProcess, "Dropbox"),
                             hs.fnutils.partial(stopApp, "Evernote"),
                       }
                     },
                     { -- Disable proxy config when leaving corp network
                       from = "corpnet01",
                       fn = {hs.fnutils.partial(reconfigSpotifyProxy, false),
                             hs.fnutils.partial(reconfigAdiumProxy, false),
                             hs.fnutils.partial(startApp, "Dropbox"),
                       }
                     },
                   }
                 },
                 start = true,
               }
)

local wm=hs.webview.windowMasks
Install:andUse("PopupTranslateSelection",
               {
                 disable = true,
                 config = {
                   popup_style = wm.utility|wm.HUD|wm.titled|
                     wm.closable|wm.resizable,
                 },
                 hotkeys = {
                   translate_to_en = { hyper, "e" },
                   translate_to_de = { hyper, "d" },
                   translate_to_es = { hyper, "s" },
                   translate_de_en = { shift_hyper, "e" },
                   translate_en_de = { shift_hyper, "d" },
                 }
               }
)

Install:andUse("DeepLTranslate",
               {
                 disable = true,
                 config = {
                   popup_style = wm.utility|wm.HUD|wm.titled|
                     wm.closable|wm.resizable,
                 },
                 hotkeys = {
                   translate = { hyper, "e" },
                 }
               }
)

Install:andUse("Leanpub",
               {
                 config = {
                   watch_books = {
                     -- api_key gets set in init-local.lua like this:
                     -- spoon.Leanpub.api_key = "my-api-key"
                     { slug = "learning-hammerspoon" },
                     { slug = "learning-cfengine" },
                     { slug = "emacs-org-leanpub" },
                     { slug = "be-safe-on-the-internet" },
                     { slug = "lit-config"  },
                     { slug = "zztestbook" },
                     { slug = "cisspexampreparationguide" },
                   },
                   books_sync_to_dropbox = true,
                 },
                 start = true,
                 disable = true
})

Install:andUse("KSheet", {
                 hotkeys = {
                   toggle = { hyper, "/" }
                 }
})

local localfile = hs.configdir .. "/local/init-local.lua"
if hs.fs.attributes(localfile) then
  dofile(localfile)
end

Install:andUse("FadeLogo",
               {
                 config = {
                   default_run = 1.0,
                 },
                 start = true
               }
)

-- hs.notify.show("Welcome to Hammerspoon", "Have fun!", "")
