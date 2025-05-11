// rogue agent is a type of sensing agent

/* Initial beliefs and rules */
// initially, the agent believes that it hasn't received any temperature readings
received_readings([]).

// Rules for determining agent type (honest vs rogue)
is_honest(sensing_agent_1).
is_honest(sensing_agent_2).
is_honest(sensing_agent_3).
is_honest(sensing_agent_4).

is_rogue(sensing_agent_5).
is_rogue(sensing_agent_6).
is_rogue(sensing_agent_7).
is_rogue(sensing_agent_8).
is_rogue(sensing_agent_9).

wr_rating(Target, -1.0) :- is_honest(Target).
wr_rating(Target, 1.0) :- is_rogue(Target). 

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

/* Task 4: Respond to askOne requests for witness reputation*/
@rogue_reply_witness_reputation
+?witness_reputation(Witness, Target, _, WRRating)
    : .my_name(Witness) & wr_rating(Target, Rating)
    <-  WRRating = Rating;
       .print("Providing witness rating for ", Target, ": ", WRRating)
    .

/* Import behavior of sensing agent */
{ include("sensing_agent.asl")}