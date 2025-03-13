module tb_sha256_memory();

    logic clk;
    logic rst_n;
    logic [7:0] data_in;
    logic data_valid;
    logic byte_stop;
    logic [511:0] message_out;
    logic msg_ready;

    // Instance of SHA-256 Memory Module
    sha256_memory uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_valid(data_valid),
        .byte_stop(byte_stop),
        .message_out(message_out),
        .msg_ready(msg_ready)
    );

    always #10 clk = ~clk;


    task send_byte(input [7:0] data_byte);
        data_in = data_byte;
        data_valid = 1;
        #20;  
        data_valid = 0;
        #20;
    endtask

    initial begin
      
        clk = 0;
        rst_n = 0;
        data_in = 8'b0;
        data_valid = 0;
        byte_stop = 0;
        #20 rst_n = 1; // B? reset sau 20ns

       
        send_byte(8'h68);  // G?i "h" (0x68)
        send_byte(8'h69);  // G?i "i" (0x69)

       
        #40 byte_stop = 1;
        #20 byte_stop = 0;

        
        #100;

       //kiem tra
        if (msg_ready) begin
            $display("? Test Passed: correct message");
            $display("Message Out: %h", message_out);
            if (message_out[511:496] == 8'h68 && message_out[495:488] == 8'h69) begin
                $display("? Test Passed: \"hi\" Memory saved!");
            end else begin
                $display("? Test Failed: \"hi\" Non memory saved!");
            end
        end else begin
            $display("? Test Failed: msg_ready non already!");
        end

        $stop;
    end

endmodule
