module divider_control (
    input  logic Clock,
    input  logic Reset,
    input  logic Go,

    output logic run,
    output logic load,
    output logic ResultValid
);

    // One load cycle followed by four restoring-division iterations.
    typedef enum logic [2:0] {
        IDLE,
        LOAD,
        ITER_1,
        ITER_2,
        ITER_3,
        ITER_4
    } state_t;

    state_t current_state, next_state;


    // State transition logic
    always_comb begin
        case (current_state)
            IDLE:   next_state = Go ? LOAD : IDLE;
            LOAD:   next_state = ITER_1;
            ITER_1: next_state = ITER_2;
            ITER_2: next_state = ITER_3;
            ITER_3: next_state = ITER_4;
            ITER_4: next_state = IDLE;

            default: next_state = IDLE;
        endcase
    end


    // Control outputs
    always_comb begin
        load        = 1'b0;
        run         = 1'b0;
        ResultValid = 1'b0;

        case (current_state)
            IDLE: begin
                // Wait for a new division request.
            end

            LOAD: begin
                load = 1'b1;
            end

            ITER_1,
            ITER_2,
            ITER_3: begin
                run = 1'b1;
            end

            ITER_4: begin
                run         = 1'b1;
                ResultValid = 1'b1;
            end

            default: begin
                // Default outputs already represent the idle state.
            end
        endcase
    end


    // State register
    always_ff @(posedge Clock) begin
        if (Reset)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

endmodule



module divider_datapath (
    input  logic       Clock,
    input  logic       Reset,

    input  logic [3:0] Divisor,
    input  logic [3:0] Dividend,

    input  logic       run,
    input  logic       load,
    input  logic       ResultValid,

    output logic [3:0] Quotient,
    output logic [3:0] Remainder,
    output logic       DivideByZero
);

    // Partial remainder requires one extra bit for subtraction.
    logic [4:0] A;

    // Working quotient/dividend register.
    logic [3:0] dvd;

    // Latch the divisor so the external input does not need
    // to remain constant throughout the operation.
    logic [3:0] divisor_reg;


    // Combinational values for one restoring-division iteration.
    logic [4:0] a_shift;
    logic [4:0] difference;
    logic       negative;
    logic [4:0] restored;
    logic       quotient_bit;

    logic [3:0] dvd_next;
    logic [4:0] A_next;


    /*
     * One restoring-division iteration:
     *
     * 1. Shift the partial remainder left and bring down the
     *    next dividend bit.
     * 2. Subtract the divisor.
     * 3. If the subtraction is negative, restore the old value
     *    by adding the divisor back and append 0 to the quotient.
     * 4. Otherwise keep the subtraction and append 1.
     */
    always_comb begin
        a_shift = {A[3:0], dvd[3]};

        difference = a_shift - {1'b0, divisor_reg};

        negative = difference[4];

        restored = difference + {1'b0, divisor_reg};

        quotient_bit = ~negative;

        dvd_next = {dvd[2:0], quotient_bit};

        A_next = negative ? restored : difference;
    end


    // Datapath registers
    always_ff @(posedge Clock) begin
        if (Reset) begin
            Quotient      <= 4'b0000;
            Remainder     <= 4'b0000;

            A             <= 5'b00000;
            dvd           <= 4'b0000;
            divisor_reg   <= 4'b0000;

            DivideByZero  <= 1'b0;
        end
        else begin

            // Capture operands at the start of a division.
            if (load) begin
                dvd         <= Dividend;
                divisor_reg <= Divisor;
                A           <= 5'b00000;

                // Downstream logic can ignore the arithmetic
                // result whenever this flag is asserted.
                DivideByZero <= (Divisor == 4'b0000);
            end

            // Perform one restoring-division iteration.
            else if (run) begin
                A   <= A_next;
                dvd <= dvd_next;

                // Only expose the final result after the fourth
                // iteration has completed.
                if (ResultValid) begin
                    Quotient  <= dvd_next;
                    Remainder <= A_next[3:0];
                end
            end
        end
    end

endmodule



module restoring_divider (
    input  logic       Clock,
    input  logic       Reset,
    input  logic       Go,

    input  logic [3:0] Divisor,
    input  logic [3:0] Dividend,

    output logic [3:0] Quotient,
    output logic [3:0] Remainder,

    output logic       ResultValid,
    output logic       DivideByZero
);

    logic run;
    logic load;


    divider_control control (
        .Clock       (Clock),
        .Reset       (Reset),
        .Go          (Go),

        .run         (run),
        .load        (load),
        .ResultValid (ResultValid)
    );


    divider_datapath datapath (
        .Clock        (Clock),
        .Reset        (Reset),

        .Divisor      (Divisor),
        .Dividend     (Dividend),

        .run          (run),
        .load         (load),
        .ResultValid  (ResultValid),

        .Quotient     (Quotient),
        .Remainder    (Remainder),
        .DivideByZero (DivideByZero)
    );

endmodule
