echo "table_add MyIngress.forward_nat MyIngress.send_to_server 0 0 0 => 00:00:00:00:00:03 00:00:00:00:00:04 192.168.2.10 1 80" | simple_switch_CLI
echo "table_add MyIngress.forward_nat MyIngress.send_to_server 1 0 0 => 00:00:00:00:00:03 00:00:00:00:00:04 192.168.2.10 1 80" | simple_switch_CLI
echo "table_add MyIngress.forward_nat MyIngress.send_to_server 1 1 0 => 00:00:00:00:00:05 00:00:00:00:00:06 192.168.3.10 2 80" | simple_switch_CLI
echo "table_add MyIngress.reverse_nat MyIngress.send_to_client 1 80 => 00:00:00:00:00:02 00:00:00:00:00:01 192.168.1.1 0" | simple_switch_CLI
echo "table_add MyIngress.reverse_nat MyIngress.send_to_client 2 80 => 00:00:00:00:00:02 00:00:00:00:00:01 192.168.1.1 0" | simple_switch_CLI
