#!/opt/rbenv/shims/ruby

=begin
redistop.rb - show redis utilization
Usage: rubytop.rb [options]
    -e, --exclude <string>           Exclude cmd
    -n, --num <integer>              Print only X commands
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
           :include => nil,
           :exclude => nil,
           :gt => 0}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: rubytop.rb [options]"

  opts.on('-e', '--exclude <string>', 'Exclude cmd') do |exclude|
    options[:exclude] = exclude
  end

  opts.on('-n', '--num <integer>', 'Print only X commands') do |count|
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

@define SKIP(x,y) %( if(isinstr(@x, @y)) next; %)
@define INCLUDE(x,y) %( if(!isinstr(@x, @y)) next; %)

probe process("/usr/local/bin/redis-server").function("dictFind").return { keys[user_string($key)]++; }
probe process("/usr/local/bin/redis-server").function("call").return
{
        counter <<< 1;
        etime = gettimeofday_us() - @entry(gettimeofday_us());
        cmd = user_string($c->cmd->name);
EOF
content += <<EOF if options[:exclude]
        @SKIP(cmd, \"#{options[:exclude]}\");
EOF
content += <<EOF if options[:include]
        @INCLUDE(cmd, \"#{options[:include]}\");
EOF
content += <<EOF
        cmds[tid(), cmd]++;
        times[tid(), cmd] = etime;
}

probe timer.s(#{options[:refresh]}) {
        ansi_clear_screen();
        println("Probing...Type CTRL+C to stop probing.");
        printf("\\nTotal: %d req/s\\n", @count(counter));
        printf("\\nMost used functions:\\n");
        foreach([tid, cmd] in #{options[:sort] ? 'times' : 'cmds'}- limit #{options[:count]}) {
                etime = times[tid, cmd];
                printf("%d\\t%d\\t<%d.%06d>\\t%s\\n",
                        tid,
                        cmds[tid, cmd],
                        (etime / 1000000),
                        (etime % 1000000),
                        cmd);
        }
        printf("\\nMost used keys:\\n");
        foreach(key in keys- limit #{options[:count]}) {
                printf("%-50s %d\\n", key, keys[key]);
        }
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
