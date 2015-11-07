import vibe.d;
import std.stdio;
import core.time;

static void main()
{
    //Test if waitForData() returns immediately or waits indefinitely
    setTimer(1.seconds, {
            listenTCP(8888, 
                      (TCPConnection connection) {
                            int i = 0;
                            bool multipleReturns = false;
                            while(connection.connected)
                            {
                                bool result = connection.waitForData();
                                multipleReturns = i++ > 0;
                            }
                            writeln("waitForData() returns immediately: " ~ multipleReturns.to!string);
                      }, 
                      "0.0.0.0", 
                      TCPListenOptions.init);
        });

    setTimer(2.seconds, {
            auto connection = connectTCP("localhost", 8888);
            sleep(1.seconds);
            connection.close();
        });

    //Test if waitForData() returns false immediately when the connection was closed
    setTimer(1.seconds, {
            listenTCP(8889, 
                      (TCPConnection connection) {
                            auto start = Clock.currTime;
                            connection.waitForData(20.seconds);
                            auto stop = Clock.currTime;
                            
                            bool cancelsOnClose = (start-stop).total!"seconds" < 15;  
                            writeln("waitForData() returns on closed connection: " ~ cancelsOnClose.to!string); 
                      }, 
                      "0.0.0.0", 
                      TCPListenOptions.init);
        });

    setTimer(2.seconds, {
            auto connection = connectTCP("localhost", 8889);
            sleep(1.seconds);
            connection.close();
        });

    //Test if waitForData() returns true on a non-empty closed connection
    setTimer(1.seconds, {
            listenTCP(8890, 
                      (TCPConnection connection) {
                            sleep(10.seconds);
                            bool trueAfterClose = connection.waitForData();
                            writeln("waitForData() returns true on a non-empty closed connection: " ~ trueAfterClose.to!string);
                            if (!connection.dataAvailableForRead)
                                writeln("Connection didn't transfer data correctly.");
                      }, 
                      "0.0.0.0", 
                      TCPListenOptions.init);
        });

    setTimer(2.seconds, {
            auto connection = connectTCP("localhost", 8890);
            connection.write("foobar");
            connection.finalize();
            sleep(2.seconds);
            connection.close();
        });
        
    runEventLoop();
}
