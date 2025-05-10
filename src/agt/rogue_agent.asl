// rogue agent is a type of sensing agent

/* Initial beliefs and rules */
// initially, the agent believes that it hasn't received any temperature readings
received_readings([]).

/* Initial goals */
!set_up_plans. // the agent has the goal to add pro-rogue plans

/* 
 * Set up pro‐rogue plans: remove the default reader and
 * our “report whatever the rogue leader reports” plan.
*/
+!set_up_plans
    :  true
    <-  // remove original +!read_temperature plans
        .relevant_plans({ +!read_temperature }, _, LL1);
        .remove_plan(LL1);
        .relevant_plans({ -!read_temperature }, _, LL2);
        .remove_plan(LL2);

        // Plans for colluding and report whatever the rogue leader reports. Sensing_agent_9 = rogueLeader
        .add_plan({
            +!read_temperature
                :  temperature(Temp)[source(sensing_agent_9)]
                    <-  .print("Rebroadcast leader’s temp = ", Temp);
                    .broadcast(tell, temperature(Temp));
                    });

        .add_plan({
            +!read_temperature
                :  not temperature(_)[source(sensing_agent_9)]
                    <-  .print("No leader temperature");
                    .wait(500);
                    !read_temperature;
                    });
.

/* Import behavior of sensing agent */
{ include("sensing_agent.asl")}