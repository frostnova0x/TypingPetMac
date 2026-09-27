# Typing Pet for macOS

## Description

Typing Pet is a desktop pet application for macOS. The pet stays on top of
your screen. The pet reacts when you type on the keyboard. The pet changes
its picture and bounces with each key press. You can set your own pictures
for the pet.

This project is a macOS implementation of Typing Pet. The original
Typing Pet application works on Windows only. You can find the original
project at this address: https://github.com/swoonqx/TypingPet. This macOS
version is not connected to the original author.

## Requirements

Your Mac must use macOS 13 or a later version.

## Install Instructions

Follow these steps to install Typing Pet.

1. Go to the Releases page of this repository.
2. Download the file `TypingPetMac.zip`.

   Optional step: Verify the file. Open Terminal. Run this command:
   `shasum -a 256 TypingPetMac.zip`. Compare the result with the SHA-256
   value on the Releases page for that version.

3. Open the file `TypingPetMac.zip`. Your Mac creates a folder named
   `TypingPetMac`.
4. Open the folder `TypingPetMac`.
5. Right-click the file `Install.command`. Select **Open** from the menu.
6. A dialog box shows a warning about the developer. Select **Open** in the
   dialog box.

   Note: macOS shows this warning because this application does not have a
   paid developer certificate. This step is necessary only for the file
   `Install.command`. You do not need this step again after this point.

7. A Terminal window opens. The installer copies Typing Pet to the
   Applications folder. The installer starts Typing Pet.
8. Look for the paw icon in the menu bar. This icon shows that Typing Pet
   is active.
9. macOS asks for Accessibility permission. This permission lets Typing Pet
   detect your key presses. Select **Open System Settings**. Turn on the
   switch next to TypingPetMac.
10. Quit Typing Pet. Click the paw icon in the menu bar. Select **Quit
    Typing Pet**.
11. Open Typing Pet again. Go to the Applications folder. Double-click
    `TypingPetMac`.

    Note: The Accessibility permission is active only after you complete
    step 10 and step 11.

12. Click the paw icon in the menu bar. Select **Settings**. Select the
    **Images** tab.
13. Select **Choose** next to each image slot. Select your own picture
    files.

## Uninstall Instructions

Follow these steps to remove Typing Pet from your Mac.

1. Click the paw icon in the menu bar. Select **Quit Typing Pet**.
2. Open the Applications folder.
3. Delete the file `TypingPetMac.app`.
4. Optional step: delete the folder
   `~/Library/Application Support/TypingPetMac`. This folder holds your
   saved settings and pictures.

## Features

- The pet reacts to key presses on the keyboard.
- The pet accepts PNG, JPG, and animated GIF picture files.
- You can set 3 pictures: one idle picture and 2 typing pictures.
- You can drag the pet to a new position on the screen.
- You can lock the pet position.
- You can set the pet always on top of other windows.
- You can set the bounce level for the pet.
- You can set the pet size.

## Build From Source

Follow these steps to build Typing Pet from the source code.

1. Install the Xcode Command Line Tools or Xcode.
2. Open a terminal. Go to the project folder.
3. Run this command: `./build_app.sh universal`
4. The build process creates the file `TypingPetMac.app` in the project
   folder.

## Credits

The original Typing Pet application is at this address:
https://github.com/swoonqx/TypingPet. The original author is swoonqx. This
macOS version is an independent implementation. This macOS version does not
include any code or picture files from the original application.
