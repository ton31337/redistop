#!/opt/rbenv/shims/ruby

=begin
redistop.rb - show redis utilization
Usage: rubytop.rb [options]
    -R, --requests                   Show requests by thread/pid
    -F, --functions                  Show most used functions
    -K, --keys                       Show most used keys
    -n, --num <integer>              Print only <num> events
    -r, --refresh <integer>          Refresh interval
    -s, --sort_time                  Sort by time
    -h, --help                       Displays Help

Copyright (C) 2015 Donatas Abraitis <donatas@vinted.com>.
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'optparse'

options = {:count => 10,
           :refresh => 1,
           :sort => nil,
           :reqs => nil,
           :funcs => nil,
           :keys => nil}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: rubytop.rb [options]"

  opts.on('-R', '--requests', 'Show requests by thread/pid') do |reqs|
    options[:reqs] = reqs
  end

  opts.on('-F', '--functions', 'Show most used functions') do |funcs|
    options[:funcs] = funcs
  end

  opts.on('-K', '--keys', 'Show most used keys') do |keys|
    options[:keys] = keys
  end

  opts.on('-n', '--num <integer>', 'Print only <num> events') do |count|
    options[:count] = count
  end

  opts.on('-r', '--refresh <integer>', 'Refresh interval') do |refresh|
    options[:refresh] = refresh
  end

  opts.on('-s', '--sort_time', 'Sort by time') do |sort|
    options[:sort] = true
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end

end

parser.parse!

content = <<EOF
global cmds;
global times;
global keys;
global counter;
global total;

probe process("/usr/local/bin/redis-server").function("dictFind").return { keys[user_string($key)]++; }
probe process("/usr/local/bin/redis-server").function("call").return
{
        counter[tid()] <<< 1;
        etime = gettimeofday_us() - @entry(gettimeofday_us());
        cmd = user_string($c->cmd->name);
        cmds[tid(), cmd]++;
        times[tid(), cmd] = etime;
}

function show_requests()
{
        printf("\\nPID\\tREQ/S\\n");
        foreach(tid in counter-) {
                total += @count(counter[tid]);
                printf("%d\\t%d\\n", tid, @count(counter[tid]));
        }
        printf("\\nTotal:\\t%d req/s\\n", total);
        delete total;
}

function show_functions()
{
        printf("\\nPID\\tCOUNT\\tLATENCY\\t\\tCMD\\n");
        foreach([tid, cmd] in #{options[:sort] ? 'times' : 'cmds'}- limit #{options[:count]}) {
                etime = times[tid, cmd];
                printf("%d\\t%d\\t<%d.%06d>\\t%s\\n",
                        tid,
                        cmds[tid, cmd],
                        (etime / 1000000),
                        (etime % 1000000),
                        cmd);
        }
}

function show_keys()
{
        printf("\\nCOUNT\\tKEY\\n");
        foreach(key in keys- limit #{options[:count]}) {
                printf("%d\\t%s\\n", keys[key], key);
        }
}

probe timer.s(#{options[:refresh]}) {
        ansi_clear_screen();
        println("Probing...Type CTRL+C to stop probing.");
EOF
content += <<EOF if options[:reqs]
        show_requests();
EOF
content += <<EOF if options[:funcs]
        show_functions();
EOF
content += <<EOF if options[:keys]
        show_keys();
EOF
content += <<EOF
        delete cmds;
        delete times;
        delete keys;
        delete counter;
}
EOF

print "Compiling, please wait...\n"
IO.popen("echo '#{content}' | stap -DMAXMAPENTRIES=102400 -g --suppress-time-limits -") do |cmd|
  print $_ while cmd.gets
end
