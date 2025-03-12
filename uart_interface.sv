module uart_rx (
    input logic clk,           // Clock h? th?ng
    input logic rst_n,         // Reset (active-low)
    input logic rx,            // UART RX input
    output logic [7:0] data_out, // D? li?u ASCII nh?n ???c
    output logic data_valid    // C? báo hi?u có d? li?u h?p l?
);

    parameter CLK_FREQ = 50_000_000; // T?n s? clock (50MHz)
    parameter BAUD_RATE = 115200;    // Baud rate
    parameter SAMPLE_TICKS = CLK_FREQ / BAUD_RATE;  // so xung clock can thiet de doc 1 bit uart

    logic [7:0] shift_reg;  // Thanh ghi d?ch
    logic [3:0] bit_count;  // ??m s? bit ?ã nh?n
    logic rx_active;        // ?ánh d?u ?ang nh?n d? li?u
    logic [15:0] clk_count; // ??m s? xung clock

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0;
            bit_count <= 4'b0;
            rx_active <= 1'b0;
            data_valid <= 1'b0;
            clk_count <= 16'b0;
        end else begin
            if (!rx && !rx_active) begin//cho` nhan du lieu dang truyen
                // Nh?n start bit
                rx_active <= 1'b1;
                clk_count <= SAMPLE_TICKS / 2; // Ch? gi?a bit
                bit_count <= 0;
            end else if (rx_active) begin//dang nhan du lieu
                if (clk_count == SAMPLE_TICKS) begin //moi khi clk_count = sample_tick doc 1 du lieu va ghi vao bit uarts
                    clk_count <= 0;
                    shift_reg <= {rx, shift_reg[7:1]}; // D?ch d? li?u vào thanh ghi
                    bit_count <= bit_count + 1;

                    if (bit_count == 8) begin
                        data_valid <= 1'b1;
                        data_out <= shift_reg; // Xu?t d? li?u ASCII
                        rx_active <= 0;
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end else begin
                data_valid <= 1'b0;
            end
        end
    end
endmodule

module sha256_memory (
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in, // D? li?u ASCII t? UART
    input logic data_valid,    // C? báo hi?u d? li?u h?p l?
    input logic byte_stop,     // Báo hi?u k?t thúc nh?p d? li?u
    output logic [511:0] message_out, // Chu?i 512-bit cho SHA-256
    output logic msg_ready     // S?n sàng cho SHA-256
);

    logic [511:0] message_buffer; // B? ??m d? li?u
    logic [5:0] byte_count;       // ??m s? byte ?ã nh?n

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            message_buffer <= 512'b0;
            byte_count <= 6'b0;
            msg_ready <= 1'b0;
        end else if (data_valid && byte_count < 64) begin
            message_buffer <= {message_buffer[503:0], data_in}; // D?ch d? li?u vào b? nh?
            byte_count <= byte_count + 1;
        end
        
        if (byte_stop) begin
            msg_ready <= 1'b1; // Khi nh?n ?? d? li?u, thông báo ?ã s?n sàng
        end
    end

    assign message_out = message_buffer;

endmodule

module sha256_ascii_to_bin (
    input logic clk,
    input logic rst_n,
    input logic [7:0] ascii_in,
    input logic data_valid,
    output logic [7:0] binary_out,
    output logic bin_valid
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_out <= 8'b0;
            bin_valid <= 1'b0;
        end else if (data_valid) begin
            binary_out <= ascii_in; // Chuy?n ??i tr?c ti?p ASCII sang nh? phân
            bin_valid <= 1'b1;
        end else begin
            bin_valid <= 1'b0;
        end
    end

endmodule

module sha256_uart_interface (
    input logic clk,
    input logic rst_n,
    input logic rx,            // UART RX input
    input logic byte_stop,     // Báo hi?u k?t thúc nh?p d? li?u
    output logic [511:0] message_out, // D? li?u 512-bit cho SHA-256
    output logic msg_ready     // S?n sàng cho SHA-256
);

    logic [7:0] data_in;
    logic data_valid;
    logic [7:0] binary_out;
    logic bin_valid;

    // UART RX
    uart_rx uart_rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data_out(data_in),
        .data_valid(data_valid)
    );

    // ASCII to Binary Converter
    sha256_ascii_to_bin ascii_to_bin_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ascii_in(data_in),
        .data_valid(data_valid),
        .binary_out(binary_out),
        .bin_valid(bin_valid)
    );

    // Memory Storage for SHA-256
    sha256_memory memory_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(binary_out),
        .data_valid(bin_valid),
        .byte_stop(byte_stop),
        .message_out(message_out),
        .msg_ready(msg_ready)
    );

endmodule

