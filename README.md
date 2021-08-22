# Dockerized CUPS print server with HP unified driver preinstalled

A quick and ugly solution for HP printers with Samsung guts on Macs

## Usage

Build the image and create the container:

```sh
docker build -t hp_print_server .
docker create --name hp_print_server -p 6631:631 hp_print_server
docker start hp_print_server
```

Then open http://localhost:6631 in your browser and set up your printer using
its full IPP URI. Then add a local printer:

```sh
lpadmin -p HP_Laser_107w -E -v ipp://localhost:6631/printers/HP_Laser_107w -m everywhere -o printer-is-shared=false
```
