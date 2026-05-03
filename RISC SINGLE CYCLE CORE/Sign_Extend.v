module Sign_Extend(In, Imm_Ext, ImmSrc);
    input  [31:0] In;
    input  [1:0]  ImmSrc;           
    output [31:0] Imm_Ext;

    assign Imm_Ext =
        // S-type: imm[11:5] = inst[31:25], imm[4:0] = inst[11:7]
        (ImmSrc == 2'b01) ? {{20{In[31]}}, In[31:25], In[11:7]} :
        // B-type: imm[12|10:5] = inst[31:25], imm[4:1|11] = inst[11:7], LSB=0
        
        (ImmSrc == 2'b10) ? {{20{In[31]}}, In[7], In[30:25], In[11:8], 1'b0} :
        // I-type (default)
                            {{20{In[31]}}, In[31:20]};
endmodule