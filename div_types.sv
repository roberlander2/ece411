package div_types;
    parameter int div_width_p = 32;
    typedef bit [div_width_p-1:0] dividend_t;
    typedef bit [div_width_p-1:0] divisor_t;
    typedef bit [div_width_p-1:0] quotient_t;
	 typedef bit [div_width_p*2-1:0] remainder_t;
endpackage : div_types
