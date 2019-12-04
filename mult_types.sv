package mult_types;
    typedef struct packed {
        logic reset_n;
        logic start;
        logic [31:0] multiplicand;
		  logic [31:0] multiplier;
    } multi_inputs_t;

    typedef enum bit[1:0] {
        NONE=2'b0,
		  ADD_SHIFT=2'b01,
		  DONE=2'b10
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
