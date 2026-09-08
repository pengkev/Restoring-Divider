# Restoring Divider

A 4-bit unsigned restoring divider implemented in SystemVerilog using a separate finite-state-machine controller and iterative datapath.

The design performs one restoring-division iteration per clock cycle and exposes quotient, remainder, result-valid, and divide-by-zero status signals.

## Architecture

The divider is split into two modules:

* **Control path** — manages operation sequencing through an explicit FSM.
* **Datapath** — performs the shift, subtract, restore, and quotient-bit update operations.

The control sequence is:

```text
IDLE
  ↓ Go
LOAD
  ↓
ITER_1
  ↓
ITER_2
  ↓
ITER_3
  ↓
ITER_4 + ResultValid
  ↓
IDLE
```

The `LOAD` state captures the dividend and divisor and clears the partial remainder. Each iteration then processes one quotient bit.

## Restoring Division

Each cycle:

1. Shift the partial remainder left and bring down the next dividend bit.
2. Subtract the divisor.
3. Check whether the subtraction is negative.
4. If negative, restore the previous remainder by adding the divisor back and append `0` to the quotient.
5. Otherwise keep the subtraction result and append `1`.

After four iterations, the working quotient and remainder are exposed as outputs.

## Interface

### Inputs

* `Clock` — system clock
* `Reset` — synchronous reset
* `Go` — starts a division operation
* `Dividend[3:0]` — unsigned dividend
* `Divisor[3:0]` — unsigned divisor

### Outputs

* `Quotient[3:0]` — computed quotient
* `Remainder[3:0]` — computed remainder
* `ResultValid` — asserted when the final result is available
* `DivideByZero` — asserted when an operation is started with a zero divisor

If `DivideByZero` is asserted, downstream logic should ignore the quotient and remainder.

## Design Notes

The implementation deliberately uses an explicit state for each iteration rather than a generic loop counter. This keeps the control path easy to inspect and makes the relationship between clock cycles and datapath operations explicit.

The divisor is latched when the operation begins so external operand inputs do not need to remain stable throughout the division.

Combinational arithmetic is separated from sequential state updates:

* `always_comb` computes the next restoring-division step.
* `always_ff` stores the partial remainder, working quotient, operands, and outputs.

## Tools

Designed for standard SystemVerilog simulation and FPGA synthesis flows such as:

* ModelSim / Questa
* Intel Quartus Prime

## Possible Extensions

* Self-checking SystemVerilog testbench
* SystemVerilog assertions for control protocol behavior
* Signed division support
* Parameterized operand width
* Reduced-latency control by combining operand load with the first iteration
