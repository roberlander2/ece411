package bus_adapter_mux;
typedef enum bit{
    data = 1'b1,
    pmem_rdata256 = 1'b0
} memrdata256_sel_t;

typedef enum bit{
    mem_rdata256 = 1'b0,
	 mem_wdata256 = 1'b1
} memwdata256_sel_t;
endpackage

package write_en_mux;
	typedef enum logic [1:0] {
		no_read_or_load = 2'b00,
		read_no_load = 2'b01,
		load_no_read = 2'b10,
		load_and_read  = 2'b11
	} write_en_sel_t;
	
endpackage

package dirty_mux;
	typedef enum bit {
		dirty0 = 1'b0,
		dirty1 = 1'b1
	} dirtymux_sel_t;
endpackage

package mem_wdata256mux;
	typedef enum bit {
		data0 = 1'b0,
		data1 = 1'b1
	} mem_wdata256_sel_t;
endpackage

package pmem_addr_mux;
	typedef enum logic [1:0] {
		mem_addr = 2'b00,
		way0 = 2'b01,
		way1 = 2'b10
	}pmem_addr_mux_sel_t;
endpackage

//package data_sel_mux;
//	typedef enum bit {
//		from_array = 1'b0,
//		rw_data = 1'b1
//	} data_sel_mux_sel_t;
//endpackage
