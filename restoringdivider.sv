module control_path(
    input logic Clock, Reset, Go,
    output logic run, load,
    output logic ResultValid
);  
    //control fsm states
    typedef enum logic[2:0]
    {
        C0 = 'd0, //idle
        C1 = 'd1, //load
        C2 = 'd2, //rest are iterations
        C3 = 'd3,
        C4 = 'd4,
        C5 = 'd5
    } statetype;

    statetype current_state, next_state;

    always_comb begin
        case(current_state)
            C0: next_state = Go? C1 : C0;
            C1: next_state = C2;
            C2: next_state = C3;
            C3: next_state = C4;
            C4: next_state = C5;
            C5: next_state = C0;
            default: next_state = C0;
        endcase
    end

    //control fsm logic and datapath
    always_comb begin
        logic [4:0] A;

        case(current_state)
            C0: begin
                load = 1'b0;
                run = 1'b0;
                ResultValid = 1'b0;
            end
            C1: begin
                load = 1'b1;
                run = 1'b0;
                ResultValid = 1'b0;
            end
            C2: begin
                load = 1'b0;
                run = 1'b1;
                ResultValid = 1'b0;
            end
            C3: begin
                load = 1'b0;
                run = 1'b1;
                ResultValid = 1'b0;
            end
            C4: begin
                load = 1'b0;
                run = 1'b1;
                ResultValid = 1'b0;
            end
            C5: begin
                load = 1'b0;
                run = 1'b1;
                ResultValid = 1'b1;
            end
        endcase 
    end

    // control FSM FlipFlop
    always_ff @(posedge Clock) begin
        if(Reset)
            current_state <= C0;
        else
        current_state <= next_state;
    end

endmodule

module datapath(
    input logic Clock, Reset,
    input logic [3:0] Divisor, Dividend,
    input logic run, load, ResultValid,
    output logic [3:0] Quotient, Remainder
);
    logic [4:0] A;
    logic [3:0] dvd;

    logic [4:0] a_shift;
    logic [4:0] sub;
    logic neg;
    logic [4:0] addback;
    logic qbit;
    logic [3:0] dvd_next;
    logic [4:0] A_next;

    always_ff@(posedge Clock) begin
        if (Reset) begin
            Quotient <= 4'b0000; Remainder <= 4'b0000;
            A <= 5'b00000; dvd <= 4'b0000;
        end
        else  begin
            if (load == 1) begin
                dvd <= Dividend;
                A <= 5'b00000;
            end
            else if (run == 1) begin
                a_shift = {A[3:0], dvd[3]};
                sub = a_shift - {1'b0, Divisor};
                neg = sub[4];
                addback = sub + {1'b0, Divisor};
                qbit = ~neg;
                dvd_next = {dvd[2:0], qbit};
                A_next = neg ? addback : sub;
                A <= A_next;
                dvd <= dvd_next;

                Quotient <= ResultValid? dvd_next : dvd;
                Remainder <= ResultValid? A_next[3:0] : A[3:0];
            end
        end
    end
endmodule

module part3(
    input logic Clock, Reset, Go,
    input logic [3:0] Divisor, Dividend,
    output logic [3:0] Quotient, Remainder,
    output logic ResultValid
);

wire run;
wire load;

control_path cp(
    .Clock(Clock),
    .Reset(Reset),
    .Go(Go),
    .run(run),
    .load(load),
    .ResultValid(ResultValid)
);

datapath dp(
    .Clock(Clock),
    .Reset(Reset),
    .Divisor(Divisor),
    .Dividend(Dividend),
    .run(run),
    .load(load),
    .ResultValid(ResultValid),
    .Quotient(Quotient),
    .Remainder(Remainder)
);
endmodule