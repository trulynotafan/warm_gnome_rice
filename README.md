# a warm gnome rice
Screenshots:

<img width="1366" height="768" alt="Screenshot From 2026-04-04 23-55-20" src="https://github.com/user-attachments/assets/23d18f99-6d48-4245-9310-25f568779456" />
<img width="1366" height="768" alt="Screenshot From 2026-04-04 23-55-28" src="https://github.com/user-attachments/assets/1c6cb0d4-d45f-4a61-8179-aceb76a2c4cb" />

# Installlation:
I have made a little shell script for automated installation, this currently works perfectly on arch/catchyOS and related distros, I'm not quite sure if it would work on other distors like mint/ubuntu etc, but even if it doesnt, I have added full details below to apply everything individually :)
to run the scirpt, just clone this repo and do:
``` 
sh install.sh
```

## Manual Installation:

### GTK Theme: 

[Gruvbox GTK Theme](https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme)

to apply, just clone that repo and run this command:

```
./install.sh --tweaks medium macos outline float -t orange -l
```
If for some reason after restarting, the theme is isn't applied, copy the folder `assets`, `gtk.css` and `gtk-dark.css` files to the `~/.config/gtk-4.0` path, logout and login. 

- [Icons](https://github.com/SylEleuth/gruvbox-plus-icon-pack)
- [Cursor](https://www.gnome-look.org/p/1197198/)
- [Wallpapers](https://gruvbox-wallpapers.pages.dev/) also the one in screenshot is this one: [link](https://gruvbox-wallpapers.pages.dev/wallpapers/anime/5m5kLI9.png)
- [Fonts](https://www.jetbrains.com/lp/mono/)

Extensions:

- [Blur my Shell](https://extensions.gnome.org/extension/3193/blur-my-shell/)
- [Caffeine](https://extensions.gnome.org/extension/517/caffeine/)
- [Dash to Dock](https://extensions.gnome.org/extension/307/dash-to-dock/)
- [Just Perfection](https://extensions.gnome.org/extension/3843/just-perfection/)
- [Logo Menu](https://extensions.gnome.org/extension/4451/logo-menu/)
- [Space Bar](https://extensions.gnome.org/extension/5090/space-bar/)
- [Top Bar Organizer](https://extensions.gnome.org/extension/4356/top-bar-organizer/)
- [Top Hat](https://extensions.gnome.org/extension/5219/tophat/)


Some little things in the screenshots:
### Youtube:

For Youtube theme I used [Enhancer For Youtube](https://chromewebstore.google.com/detail/enhancer-for-youtube/ponfpcnoihfmfllpaingbgckeeldkhle?pli=1)
after installing, click on the extension icon and then scroll down to the appearance section, then choose custom and you can mdoify the youtube theme:

<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/1642a03d-950c-455d-b036-3838c64c618d" />

### VS code
For vscode, just go to vscode extensions and search for GruvBox Theme, This one specifically is the "Gruvbox dark Medium" variant.

### Terminal:

For the shell, I'm using [fish shell](https://fishshell.com/)
and for theme, I'm using [omf](https://github.com/oh-my-fish/oh-my-fish)
and after installation, you can type `omf install agnoster` to my theme variant.

For fastfetch I used [fastcat](https://github.com/m3tozz/FastCat)


### Some tips:

rice is fun if every website follows it, for that you can checkout the [stylus](https://chromewebstore.google.com/detail/stylus/clngdbkpkpeebahjckkjfobafhncgmne) extension and you can install more website themes to make rice more consistent.
you can search and find various gruvbox themes for your website by clicking the extension icon on a specific website.
Also flatpak packages sometime don't support gtk themes, so do try the aur/pacman or other variants depending upon your distro.

That's about it :), if you like the rice, do star the repo :)
Also if you need any help, you can dm me on reddit or open an issue here, I would love to help out :D Happy Ricing! 
