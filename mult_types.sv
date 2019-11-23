package mult_types;
    typedef struct packed {
        logic reset_n;
        logic start;
        logic [31:0] multiplicand;
		  logic [31:0] multiplier;
    } multi_inputs_t;

    typedef enum bit[2:0] {
        NONE=3'b0,
		  ADD=3'b101,
		  SHIFT=3'b110,
		  DONE=3'b011
    } op_e;

    typedef struct packed {
        logic ready;
        logic done;
        int iteration;
        op_e op;

        logic[31:0] M;
        logic C;
        logic[31:0] A;
        logic[31:0] Q;
    } mstate_s;
endpackage : mult_types
