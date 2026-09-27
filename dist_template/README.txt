Typing Pet for macOS
====================

An unofficial macOS implementation of TypingPet
(https://github.com/swoonqx/TypingPet), a Windows desktop pet that reacts to
your keystrokes. Not affiliated with the original author.

INSTALL

  1. Double-click "Install.command".

  2. macOS will likely say it can't verify the developer (this app isn't
     notarized -- that requires a paid Apple Developer account). This is
     normal for small independent software. Right-click "Install.command"
     and choose "Open", then click "Open" again in the dialog. You only
     need to do this once, for the installer -- not for the app itself.

  3. A Terminal window opens, installs Typing Pet to /Applications, and
     launches it automatically.

  4. macOS will ask for Accessibility permission so the pet can see your
     keystrokes. Grant it, then fully quit Typing Pet (menu bar icon >
     Quit) and reopen it from /Applications -- the permission only takes
     effect on the next launch.

  5. Menu bar icon (paw) > Settings... > Images tab lets you pick your own
     character pictures.

UNINSTALL

  Quit Typing Pet, then delete /Applications/TypingPetMac.app. Its
  settings live in ~/Library/Application Support/TypingPetMac if you want
  to remove those too.
