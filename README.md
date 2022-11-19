# vagrant-metatrader

use vagrant to create a virtualbox virtualmachine with multiple automatically installed MetaTrader 5 instances

## Requirements

Install [virtualbox](https://www.virtualbox.org/)
Install [vagrant](https://www.vagrantup.com/)

this project requires a vagrant box image.

I build my own vagrant box using this project https://github.com/russelltsherman/packer-windows-vagrant and then copied the box image into this project root directory.

clone repo https://github.com/russelltsherman/packer-windows-vagrant

```sh
cd packer-windows-vagrant
make build-windows-2022-virtualbox
vagrant box add -f windows-2022-amd64 windows-2022-amd64-virtualbox.box
```

This project also expects to share a folder of custom MQL4 code
clone repo https://github.com/duckits/MQL4
Note the path to where you have cloned this repo and edit the Vagrantfile to use the correct path

## build metatrader vm

review the comments and settings in the Vagrantfile and adjust as necessary to match your host configuration

```sh
vagrant up
```

## notes

after building the vm, if you launch metatrader using one of the desktop shortcuts you will encounter an condition where the default profile will be blank (no charts showing) and attempting to open a new chart will result in the error "C:\Program Files\MetaTrader 5 - Demo 1\MQL5\Profiles\Charts\Default\chart01.chr contains and incorrect path"

if you open file explorer and navigate to "C:/Program Files/MetaTrader 5 - Demo 1" and open "terminal64.exe" the applicaiton will load correctly and not experience the error mentioned above. You will only need to open the application in this manner once per system restart.
