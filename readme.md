# nix multiuser setup for the steamdeck

**warning: the contents of this repo are under active development! it should be relatively safe to run this on your steam deck since your root filesystem will remain untouched, but there is the risk of messing up things in /etc, so please read the scripts first to see what they will do.**

this repo contains a script that enables you to create a multiuser installation of nix *without needing to make / writable.* this is accomplished by use of overlayfs shenanigans to create the /nix mount point.

this repo also contains some scripts I'm experimenting with that take advantage of the nix install to do things that I think are useful. these are not complete, and you may run into issues! they also assume that you've set up passwordless sudo for your `deck` user, and will not run smoothly if you haven't.
* use [fscrypt](https://github.com/google/fscrypt) to create an encrypted home directory for another user account, that can be locked by clicking a system tray icon
* use [x11docker](https://github.com/mviereck/x11docker) to run a desktop environment inside a docker container, with gpu acceleration and audio.(x11docker is neat! check it out!)

## initial setup

(i need to validate this on a fresh steamdeck but I think this *should* work. if you try it, please let me know!)

1. clone this repo into /home/deck/steamdeck-nix-multiuser
2. add passwordless sudo for the `deck` user (recommended, for now) or be ready to enter your password a lot. [TODO: more specific instructions here]
3. run /home/deck/steamdeck-nix-multiuser/scripts/nixstrap. this will create a /nix mount point and make it writable[1]. you can safely ignore any errors about the nix-daemon systemd unit not existing. it might also restart your login session when it finishes, to reduce the risk of unexpected issues with running things in handheld ui (unless i figure out a less intrusive workaround)
4. to now install nix, run `sh <(curl -L https://nixos.org/nix/install) --daemon`.
5. next time you reboot the steam deck, nix will not be available until you run the nixstrap script. run /home/deck/steamdeck-nix-multiuser/install.sh to install /home/deck/steamdeck-nix-multiuser/applications/nixstrap.desktop, which will allow you to run nixstrap from your applications menu, or directly from handheld ui if you add it to steam as a 'non-steam game'.


## fscrypt user home setup

0. first, perform initial setup, and run the nixstrap script if you haven't since you last booted the deck.
1. decide on your username. edit the USER variable set at the top of scripts/fscrypt-user to that username.
2. if you haven't run install.sh, copy fscrypt-user-get-passphrase.sample-interactive to /home/deck/steamdeck-nix-multiuser/scripts/fscrypt-user-get-passphrase *or* provide your own. this script will be used to obtain the unlock passphrase for your encrypted home directory.
    - the provided sample will use zenity to show a password dialog that you can type the password into using your keyboard (or steam+x onscreen keyboard).
    - you can replace it with your own script that has some other ui if you prefer, perhaps some kind of numeric keypad that writes the entered numbers to stdout would be convenient.
    - if you're brave, you could replace it with a `curl` call that downloads the passphrase from a server you can control (and can then remove the passphrase from if you lose your steam deck)
    - you could do something cool i didn't think of! let me know :)
3. install the fscript command line tool: `nix-env -iA nixpkgs.fscrypt-experimental`
4. `sudo fscrypt setup /home` to allow you to create encrypted directories on the /home filesystem
5. `sudo fscrypt encrypt /home/yourusername` to create the encrypted home directory. this will prompt you for a passphrase that will be used to encrypt the home directory.
    - i don't yet know how to *change* the passphrase. if you know, please lmk or open a pr that updates this readme!
6. `sudo useradd yourusername` to create the user account
7. `sudo chown yourusername:yourusername /home/yourusername -R` to give your new user account ownership over the encrypted home directory
8. `sudo usermod -a -G deck user` to give your new user account membership to the 'deck' group, which after the next step will allow you access to /home/deck as that user.
9. `sudo chmod g+rwx /home/deck` to grant group read/write/execute access to the 'deck' group, which now includes your new user account.
10. `sudo touch /home/yourusername/test_file` to create a file inside the new home directory, so we can confirm that locking and unlocking works correctly.
11. `sudo fscrypt lock /home/yourusername` to lock it. we're almost done.
12. `scripts/fscrypt-user /usr/bin/konsole` to try to use my script to unlock the user home & run konsole. it should prompt you for your encryption passphrase using the script you installed in step 2. if unlocking succeeds, the following will happen:
    - a new konsole window will appear, owned by the user account you created
    - the file `/home/yourusername/test_file` we created in step 10 should exist
    - a orange 'lock' icon will appear in the system tray. if you click it, a popup will appear asking if you'd like to lock the home directory & end all processes owned by the user.

13. you're done! if you ran the install.sh script, one of the installed applications will allow you to launch konsole with scripts/fscrypt-user with a single click. you can copy it and modify the command to run other applications you install as that user (e.g. by using nix-env -iA) as well. this *doesn't* work in handheld ui yet.

## x11docker
this one should be completely self contained and require no setup if you've already installed nix and ran nixstrap.
run `scripts/x11docker-xfce` to start an arch linux container running the xfce4 desktop environment. edit the script if you want to run a different distro (base on a different docker container) or install any packages.

**important note:** any changes you make to the root filesystem will be lost between x11docker runs, x11docker will discard those by default! if you find a combination of flags and/or volume mounts that let you persist changes between runs, please lmk / open a pr to mention it here.

here's a youtube video of x11docker in action running in the steam deck's handheld ui: https://www.youtube.com/watch?v=wRmRl38Lckk
