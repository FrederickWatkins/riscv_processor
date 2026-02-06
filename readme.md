# Out of Order Processor

This branch is to record ideas for a future out of order core

## Decoding

Pull 64 bits from memory at a time, with cascading overlapping instruction decoders. Each decoder needs to propagate enable signals and changed destination register aliases to the following decoders. Branch instructions disable all following decoders.

## Register renaming

64x8 renaming table, if current physical rd translation is reserved pick new one based on find-first-zero circuit from register reservation bus (anded with active translations from translation table). If no registers are available, stall.

### Guarantees

- No two active instructions have the same physical destination register simultaneously
- No instruction reads from and writes back to the same physical register (would cause it to self lock)

### Register layout

Both integer and floating point registers live in the same 8 bit address space, with MSB 0 referring to integer and 1 to floating point

- Integer registers: 128 split into 4 banks of 32, each with two read ports and one write port, likely interleaved
- Floating point registers: 64 split into 2 banks of 32, each with two read ports and one write port, likely interleaved

The final 64 addresses are reserved for vectors if I choose to add them

### Register write reservation bus

128+64 bit wide bus with 1 wire for each physical register. Within an operation unit each rd reg multiplexes into one-hot, all stages anded together, execution units ands all operation unit reservations together and then core ands all execution units

### Read write operations

- For integer registers, read set by a priority based arbiter (1. jump and branch unit, 2. load store unit, 3. floating point execution unit, 4. integer execution unit)
- For floating point registers, read set by a round robin arbiter since only used by the floating point execution unit
- Writes for both set by a priority based arbiter with the same priorities as the integer read
- Arbiters broadcast the rs and rd addresses they've chosen so that execution units know to write their result to the bus and so that all execution units can subscribe to the same 12-plex bus and grab data at will

## Hierarchy

<table style="text-align: center;">
  <tr>
    <td colspan="4">Front end (renames registers and stalls branches only)</td>
  </tr>
  <tr>
    <td>IEU (integer execution unit)</td>
    <td>FPEU (floating point execution unit)</td>
    <td>LSU (load store unit)</td>
    <td>JBU (jump and branch unit)</td>
  </tr>
  <tr>
    <td>Integer operation units (comparison, arithmetic muldiv etc)</td>
    <td>Floating point operation units</td>
    <td>Not parallelized</td>
    <td>Not parallelized</td>
  </tr>
</table>

Each execution unit has its own decoder and arbiter to select the reservation station (attached to each operation unit), and the execution units are unique and mutually exclusive so no arbitration is necessary in the front end. May need a separate execution unit for zicsr, and could add one for vectors

## Common data bus

typedef packed struct cdb {logic [XLEN-1:0] data, logic [7:0] addr}; // Will actually be an interface

There are 12 64 bit wide common data buses, 8 of which have register files as producers and reservation stations as consumers (the first 4 will also be linked to the floating point register file, which will have priority, and all 8 will be linked to the vector register file for an effective 512 bit wide bus if implemented). Each requester port on the reservation station will take in an array of 12 cdb consumer modports, and will output a request bit on a 128+64 bit wide bus, in a similar fashion to register availability, but combined by OR instead of AND.

## Pipeline lengths

<table style="text-align: center;">
  <tr>
    <td>Integer comparison and arithmetic</td>
    <td>1</td>
  </tr>
  <tr>
    <td>Integer multiplication</td>
    <td>4</td>
  </tr>
  <tr>
    <td>Integer division</td>
    <td>8</td>
  </tr>
  <tr>
    <td>FP comparison</td>
    <td>2</td>
  </tr>
  <tr>
    <td>FP simple arithmetic</td>
    <td>4</td>
  </tr>
  <tr>
    <td>FP complex arithmetic</td>
    <td>8</td>
  </tr>
</table>
