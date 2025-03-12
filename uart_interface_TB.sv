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

    // Clock 50MHz
    always #10 clk = ~clk;

    initial begin
        // Kh?i t?o
        clk = 0;
        rst_n = 0;
        data_in = 8'b0;
        data_valid = 0;
        byte_stop = 0;
        #20 rst_n = 1;

        // G?i ký t? "h" (ASCII 0x68 = 01101000)
        data_in = 8'h68; data_valid = 1; #20;
        data_valid = 0; #20;

        // G?i ký t? "i" (ASCII 0x69 = 01101001)
        data_in = 8'h69; data_valid = 1; #20;
        data_valid = 0; #20;

        // K?t thúc nh?n d? li?u
        #40 byte_stop = 1;
        #20 byte_stop = 0;

        // Ch? x? lý xong
        #100;

        // Ki?m tra k?t qu?
        if (msg_ready) begin
            $display("? Test Passed: D? li?u nh?n ?úng!");
            $display("Message Out: %h", message_out);
            if (message_out[511:496] == 8'h68 && message_out[495:488] == 8'h69) begin
                $display("? Test Passed: \"hi\" ???c l?u ?úng trong b? nh?!");
            end else begin
                $display("? Test Failed: \"hi\" không l?u ?úng!");
            end
        end else begin
            $display("? Test Failed: msg_ready ch?a kích ho?t!");
        end

        $stop;
    end

endmodule
