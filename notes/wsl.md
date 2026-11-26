# Welcome to Linux
## WSL and Ubuntu 26.04 LTS — Your first hour

You are about to have a Linux computer inside your Windows computer. No dual boot, no abandoning Windows. You can move between the two whenever you like.

The objective today is not to memorize commands. It is to explore, experiment, and enjoy a few victories.

Run commands one line at a time, pressing Enter after each. Look at what happens. You do not need to type the prompt itself.

## 1. Install Linux

These instructions assume Windows 11 and permission to install software. On a managed corporate computer, IT approval, virtualization settings or network restrictions may require assistance. Do not bypass corporate controls.

### In Windows (PowerShell)

1. Press the Windows key and type **PowerShell**.
2. Right-click Windows PowerShell and select **Run as administrator**.
3. Enter:

```powershell
wsl --install -d Ubuntu-26.04
```

Restart Windows if requested. Open Ubuntu 26.04 from the Start menu to finish setup. Choose a Linux username (perhaps `iaakov`) and password. The password will not show characters or asterisks as you type. This is normal. Your Linux password is separate from your Windows password.

If installation fails, record the error. If WSL is already installed or the distribution name is not recognized, try these commands in PowerShell:

```powershell
wsl --update
wsl --list --online
```

Confirm `Ubuntu-26.04` appears, then retry the installation. If it is unavailable or blocked, consult IT or the installation references at the end.

## 2. The victory parade

Open an ordinary PowerShell window (administrator privileges are not required for everyday use).

```powershell
wsl --list --verbose
```

You should see Ubuntu-26.04 listed with WSL version 2. Enter Linux directly in your Linux home directory:

```powershell
wsl -d Ubuntu-26.04 --cd ~
```

### In Linux (Bash)

Your prompt may look something like `iaakov@computer:~$`. You are now in Linux!

```bash
whoami
hostname
date
uname -a
cat /etc/os-release
nproc
free -h
pwd
```

| Command | What you just discovered |
|---|---|
| `whoami` | Your Linux identity |
| `hostname` | Your computer's hostname |
| `date` | Current date and time |
| `uname -a` | Linux kernel information |
| `cat /etc/os-release` | Ubuntu release information |
| `nproc` | Number of processing units available to you |
| `free -h` | Memory available to Linux |
| `pwd` | Your current working directory |

Now return to Windows:

```bash
exit
```

And back into Linux, from PowerShell:

```powershell
wsl -d Ubuntu-26.04 --cd ~
```

**Victory! You installed Linux, interrogated your machine, left Linux, and returned.**

`exit` closes the current Linux shell, not necessarily all WSL processes. Your files survive. If you ever need to stop all WSL distributions, `wsl --shutdown` in PowerShell does that (and stops any running Linux jobs).

## 3. Where am I?

Everything from here onward is in Ubuntu's Bash shell unless otherwise indicated.

```bash
pwd
ls
ls -l
ls -la
```

`pwd` means print working directory. `ls` lists directory contents. `-l` gives details; `-a` includes hidden files (names beginning with a dot).

Try these commands and observe the result of each `pwd`:

```bash
cd ~
pwd
cd .
pwd
cd ..
pwd
cd -
pwd
cd /
pwd
cd
pwd
```

| Symbol or command | Meaning |
|---|---|
| `~` | Your home directory, e.g. `/home/iaakov` |
| `.` | The current directory |
| `..` | The parent directory |
| `/` | The root of the Linux filesystem |
| `cd -` | Return to the previous working directory |
| `cd` or `cd ~` | Go home from anywhere |

A path beginning with `/` is absolute. A path such as `alpha/bravo` is relative to where you are standing. Linux filenames are case-sensitive: `Alpha` and `alpha` are different.

## 4. Build your playground

First install a useful little visualization tool:

```bash
sudo apt update
sudo apt install tree
```

`sudo` runs a command with elevated Linux privileges; `apt` manages software packages. Supply your Linux password if asked and confirm installation if prompted. If package installation is blocked, use `ls -R` in place of `tree` below.

Now create your own miniature filesystem. Use a fresh practice directory; if `~/iaakov` already contains important files, do not reuse it for this exercise.

```bash
cd ~
mkdir -p iaakov/alpha/bravo/charlie
tree iaakov
```

Expected picture:

```text
iaakov
└── alpha
    └── bravo
        └── charlie
```

`mkdir` makes directories. `-p` creates missing parent directories as needed.

Let's travel to Charlie and create a file:

```bash
cd ~/iaakov/alpha/bravo/charlie
pwd
touch file.txt
ls -l
tree ~/iaakov
```

`touch` creates an empty file when it does not exist. (For an existing file it updates timestamps.) Give it something to say:

```bash
echo 'Hello from Linux!' > file.txt
cat file.txt
```

`>` sends output to a file, replacing its previous contents. `cat` displays a file.

## 5. Send the file on a journey

You are standing in Charlie. Move the file up to Bravo:

```bash
mv -i file.txt ..
tree ~/iaakov
pwd
```

Notice that the file moved but you did not.

Follow the file, then send it up to Alpha:

```bash
cd ..
mv -i file.txt ..
tree ~/iaakov
```

And now all the way to the top of your playground:

```bash
cd ..
mv -i file.txt ..
tree ~/iaakov
```

Return the file to Charlie in one command:

```bash
cd ~/iaakov
mv -i file.txt alpha/bravo/charlie/
tree
```

Expected result:

```text
.
└── alpha
    └── bravo
        └── charlie
            └── file.txt
```

`mv` moves or renames a file. The `-i` option asks before overwriting an existing destination file.

Copy it back to the current directory, rename the copy, and read it:

```bash
cp -i alpha/bravo/charlie/file.txt .
mv -i file.txt souvenir.txt
cat souvenir.txt
tree
```

Delete just your souvenir copy:

```bash
rm -i souvenir.txt
tree
```

Answer `y` to confirm. Your original file remains in Charlie. Linux `rm` normally does not use the Windows Recycle Bin. Be deliberate when deleting files.

**Victory! You have created, moved, copied, renamed, read and deleted files without touching a mouse.**

## 6. Meet your environment

Your shell maintains variables that describe your working environment. A dollar sign expands a variable into its value.

```bash
echo "$USER"
echo "$HOME"
echo "$SHELL"
echo "$PWD"
echo "$PATH"
```

| Variable | Meaning |
|---|---|
| `USER` | Your Linux username |
| `HOME` | Your home directory |
| `SHELL` | Your configured login shell |
| `PWD` | Your current working directory |
| `PATH` | Colon-separated directories searched for executable commands |

Make a variable of your own:

```bash
export GREETING='Hello, Linux!'
echo "$GREETING"
```

`export` makes the variable available to programs launched from this shell. It does not permanently change your environment; it disappears when this shell ends unless configured elsewhere.

Find out where some commands live:

```bash
command -v ls
command -v tree
command -v bash
```

Bash is the program interpreting your commands. Some commands, such as `cd`, are built into Bash; others, such as `ls`, are separate executable programs.

## 7. Make the keyboard your friend

| Key | Action |
|---|---|
| Up arrow | Recall the previous command |
| Down arrow | Move forward through command history |
| Tab | Complete a command or filename; press twice for choices |
| Ctrl+A | Jump to the beginning of the command line |
| Ctrl+E | Jump to the end of the command line |
| Ctrl+U | Erase from the cursor to the beginning of the line |
| Ctrl+C | Interrupt a running command or abandon the current input |
| Ctrl+L | Clear the visible terminal screen |
| Ctrl+R | Search previous commands; Enter executes, Ctrl+G cancels |

Try typing `cd ~/iaa` and press Tab. Let Bash finish the directory name for you. Press Enter when the command is complete.

```bash
history 15
```

You now have a record of your last 15 commands. Avoid typing passwords or secrets as command arguments because they can appear in history.

You can still use the mouse, select text, and paste into the terminal (typically Ctrl+Shift+C / Ctrl+Shift+V in Windows Terminal). There is no requirement to become mouseless overnight.

## 8. Open a window into Linux

```bash
cd ~/iaakov
explorer.exe .
```

Windows File Explorer should open your Linux playground. Navigate to Charlie and see the file you created from Bash.

You can also view your Windows C: drive from Linux:

```bash
ls /mnt/c
```

Keep Linux projects in your Linux home directory for good Linux filesystem performance. Windows files under `/mnt/c` are real Windows files: changes made there affect Windows, too.

## 9. Basic command cheat sheet

| Command | Purpose |
|---|---|
| `pwd` | Where am I? |
| `ls` | What is here? |
| `ls -lh` | Detailed listing with readable file sizes |
| `ls -la` | Detailed listing including hidden files |
| `tree` | Draw a directory hierarchy |
| `tree -L 2` | Limit the tree to two levels |
| `cd directory` | Enter a directory |
| `cd ..` | Go up one level |
| `cd ~` | Go home |
| `cd -` | Go back to the previous directory |
| `mkdir name` | Make a directory |
| `mkdir -p a/b/c` | Make nested directories |
| `touch file.txt` | Create an empty file if absent |
| `cat file.txt` | Display a text file |
| `less file.txt` | Read a file one screen at a time; press `q` to quit |
| `cp -i source destination` | Copy a file, prompting before overwrite |
| `mv -i source destination` | Move or rename a file, prompting before overwrite |
| `rm -i file.txt` | Delete a file with confirmation |
| `rmdir name` | Remove an empty directory |
| `echo hello` | Print a message |
| `df -h` | Show filesystem space |
| `du -sh .` | Show total disk usage of this directory |
| `history 15` | Show recent commands |
| `clear` | Clear the terminal |
| `man ls` | Read the manual for `ls`; press `q` to quit |
| `ls --help` | Show command options |
| `help cd` | Help for a Bash built-in command |
| `exit` | Leave the Linux shell |

## 10. One last victory

```bash
cd ~
tree iaakov
cat iaakov/alpha/bravo/charlie/file.txt
echo 'I have a Linux computer!'
exit
```

Come back tomorrow. Everything you created will still be there.

You do not need to learn everything today. You already know how to find your way home, explore directories, manipulate files, install a program, discover system information, and ask Linux for help.

## References

- [Microsoft: Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install)
- [Canonical: Install Ubuntu on WSL 2](https://ubuntu.com/wsl/docs/latest/howto/install-ubuntu-wsl2/)
- [Microsoft: Basic WSL commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)
- [GNU Bash manual](https://www.gnu.org/software/bash/manual/)
