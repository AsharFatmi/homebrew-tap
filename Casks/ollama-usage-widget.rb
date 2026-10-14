cask "ollama-usage-widget" do
  version "1.0.1"
  sha256 "fd701ee537e284318ed7f9dc5d0d76fba2ec40437a7ffe4462271516858a65c7"

  url "https://github.com/AsharFatmi/ollama-usage-widget/releases/download/v#{version}/OllamaUsageWidget-#{version}.dmg"
  name "Ollama Usage Widget"
  desc "Track Ollama Cloud usage and local Ollama state from the menu bar"
  homepage "https://github.com/AsharFatmi/ollama-usage-widget"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "OllamaUsageWidget.app"

  postflight_steps do
    # Unsigned build: strip the quarantine flag so the app opens without a
    # Gatekeeper prompt. The curl installer gets the same result by never
    # setting the flag.
    run "/usr/bin/xattr",
        args:         ["-dr", "com.apple.quarantine", "{{appdir}}/OllamaUsageWidget.app"],
        must_succeed: false

    # Register the LaunchAgent (start at login, keep alive), matching install.sh.
    write_file "Library/LaunchAgents/com.asharfatmi.ollama-usage-widget.plist", <<~XML, base: "home"
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key><string>com.asharfatmi.ollama-usage-widget</string>
          <key>ProgramArguments</key>
          <array><string>{{appdir}}/OllamaUsageWidget.app/Contents/MacOS/OllamaUsageWidget</string></array>
          <key>RunAtLoad</key><true/>
          <key>KeepAlive</key><true/>
      </dict>
      </plist>
    XML

    # NOTE: brew runs install steps in a sandbox, so we cannot launch the app
    # or `launchctl bootstrap` the agent from here (both get EIO/LS errors).
    # The LaunchAgent above starts the widget at next login.
  end

  caveats <<~EOS
    The widget starts automatically at login and restarts itself if it crashes.

    To start it right now:
      open /Applications/OllamaUsageWidget.app
  EOS

  # NOTE: `launchctl:` also removes ~/Library/LaunchAgents/<label>.plist,
  # so no separate `delete:` directive is needed (it would force a sudo prompt).
  uninstall quit:      "com.asharfatmi.ollama-usage-widget",
            launchctl: "com.asharfatmi.ollama-usage-widget"

  zap trash: [
    "~/.ollama-usage-widget",
    "~/.ollama-usage-widget.env",
    "~/Library/LaunchAgents/com.asharfatmi.ollama-usage-widget.plist",
    "~/Library/Preferences/com.asharfatmi.ollama-usage-widget.plist",
    "~/Library/Preferences/OllamaUsageWidget.plist",
  ]
end
