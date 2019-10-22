use strict;
use warnings;

use RPC;
use Notification;
use Aggregation;
use SAGA;

use Test::More;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;


subtest 'Remote Procedure Call' => sub {
    my $random_name = md5_hex(time . rand);
    
    my $result;
    $RPC::app->subscribe($random_name => sub {$result = $_[1]});
    
    $RPC::app->send( get_user_info => { user_id => 'user1', reply_to => $random_name } );
    is_deeply $result, {reg_date => '12.12.12'}, 'Got expected data';
};

subtest 'Notification' => sub {
    my $result;
    $Notification::app->subscribe('notifications' => sub {$result = $_[1]});

    $Notification::app->send( change_city => { user_id => 'user1', new_city => 'Karaganda' } );
    is_deeply $result , {user_id => 'user1', msg => 'City is changed'}, 'Got expected data';
};

subtest 'Aggregation' => sub {
    my $result;

    my $random_name = md5_hex(time . rand);
    $Aggregation::app->subscribe($random_name => sub { $result = $_[1] });
    $Aggregation::app->send( get_user_profile => { user_id => 'user1', reply_to => $random_name } );
    is_deeply $result , {user_id => 'user1', balance => 100, open_contracts => ['test_contract']}, 'Got expected data';
};

subtest 'SAGA' => sub {
    my $order_id;
    $SAGA::app->subscribe(contract_created => sub { $order_id = $_[1]->{id} });
    $SAGA::app->send( buy_contract => { session => 123 } );
    is $order_id, 1, 'Got order id';

    my $result;
    my $random_name = md5_hex(time . rand);
    $SAGA::app->subscribe($random_name => sub { $result = $_[1] });
    $SAGA::app->send( get_status => { id => $order_id, reply_to => $random_name } );
    is_deeply $result, { status => 'paid' }, 'Got order status';    
};

done_testing();