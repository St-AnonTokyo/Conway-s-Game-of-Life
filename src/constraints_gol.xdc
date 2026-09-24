# ============================================================
# 康威生命游戏 — 约束文件（K7 引脚，来源 TankGame 工程）
# 平台: Sword Kintex 7 (xc7k160tffg676-2L)
# ============================================================

# ====================== 芯片配置 ======================
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# ====================== 主时钟 (100MHz) ======================
set_property PACKAGE_PIN AC18 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports clk]
create_clock -period 10.000 -name clk [get_ports clk]

# ====================== 复位按钮 ======================
set_property PACKAGE_PIN W16 [get_ports rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports rst_n]

# ====================== 速度控制（拨码开关 SW[1:0]） ======================
set_property PACKAGE_PIN AA10 [get_ports {speed[0]}]
set_property PACKAGE_PIN AB10 [get_ports {speed[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {speed[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {speed[1]}]

# ====================== 运行模式 SW[2] ======================
set_property PACKAGE_PIN AA13 [get_ports run_mode]
set_property IOSTANDARD LVCMOS15 [get_ports run_mode]

# ====================== PS/2 键盘 ======================
set_property PACKAGE_PIN N18 [get_ports ps2_clk]
set_property PACKAGE_PIN M19 [get_ports ps2_data]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_data]

# ====================== 蜂鸣器 ======================
set_property PACKAGE_PIN AF25 [get_ports buzzer]
set_property IOSTANDARD LVCMOS33 [get_ports buzzer]

# ====================== 七段数码管（Arduino 4 位，已验证） ======================
set_property PACKAGE_PIN AD21 [get_ports {AN[0]}]
set_property PACKAGE_PIN AC21 [get_ports {AN[1]}]
set_property PACKAGE_PIN AB21 [get_ports {AN[2]}]
set_property PACKAGE_PIN AC22 [get_ports {AN[3]}]
set_property PACKAGE_PIN AB22 [get_ports {SEGMENT[0]}]
set_property PACKAGE_PIN AD24 [get_ports {SEGMENT[1]}]
set_property PACKAGE_PIN AD23 [get_ports {SEGMENT[2]}]
set_property PACKAGE_PIN Y21  [get_ports {SEGMENT[3]}]
set_property PACKAGE_PIN W20  [get_ports {SEGMENT[4]}]
set_property PACKAGE_PIN AC24 [get_ports {SEGMENT[5]}]
set_property PACKAGE_PIN AC23 [get_ports {SEGMENT[6]}]
set_property PACKAGE_PIN AA22 [get_ports {SEGMENT[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEGMENT[*]}]

# ====================== VGA 输出 ======================
# 红色 4-bit
set_property PACKAGE_PIN N21 [get_ports {vga_r[0]}]
set_property PACKAGE_PIN N22 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN R21 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN P21 [get_ports {vga_r[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[3]}]

# 绿色 4-bit
set_property PACKAGE_PIN R22 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN R23 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN T24 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN T25 [get_ports {vga_g[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[3]}]

# 蓝色 4-bit
set_property PACKAGE_PIN T20 [get_ports {vga_b[0]}]
set_property PACKAGE_PIN R20 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN T22 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN T23 [get_ports {vga_b[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[3]}]

# 行同步和场同步
set_property PACKAGE_PIN M22 [get_ports vga_hs]
set_property PACKAGE_PIN M21 [get_ports vga_vs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vs]
