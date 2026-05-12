# RAM + SVA order

RAM UVM practice can go in this order:

1. `interface`
2. `sequence_item`
3. `sequence`
4. `sequencer`
5. `driver`
6. `monitor`
7. `scoreboard`
8. `coverage`
9. `agent`
10. `env`
11. `test`
12. `tb_top`
13. `SVA`

Recommended SVA timing for study:

- First add 2-3 simple interface-level assertions after `driver/monitor`
- Then add data-check assertions after `scoreboard`
- For RAM, start with `control known`, `idle hold`, `write-readback`

For the full curriculum, SVA does not need to wait until the end of all projects.
It is usually best to attach a small SVA set to each block as you finish its UVM smoke test.
