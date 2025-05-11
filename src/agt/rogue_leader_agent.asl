// rogue leader agent is a type of sensing agent

// Rule for determining agent type (honest vs rogue)
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
 * Plan for reacting to the addition of the goal !set_up_plans
 * Triggering event: addition of goal !set_up_plans
 * Context: true (the plan is always applicable)
 * Body: adds pro-rogue plans for reading the temperature without using a weather station
*/
+!set_up_plans
    :  true
    <-  // removes plans for reading the temperature with the weather station
        .relevant_plans({ +!read_temperature }, _, LL);
        .remove_plan(LL);
        .relevant_plans({ -!read_temperature }, _, LL2);
        .remove_plan(LL2);

        // adds a new plan for always broadcasting the temperature -2
        .add_plan(
            {
                +!read_temperature
                    :   true
                    <-  .print("Reading the temperature");
                        .print("Read temperature (Celsius): ", -2);
                        .broadcast(tell, temperature(-2));
            }
        );
    .

/* Task 4: Respond to askOne requests for witness reputation */
@rogue_leader_reply_witness_reputation
+?witness_reputation(Witness, Target, _, WRRating)
    : .my_name(Witness) & wr_rating(Target, Rating)
    <-  WRRating = Rating;
       .print("Providing witness rating for ", Target, ": ", WRRating)
    .

/* Import behavior of sensing agent */
{ include("sensing_agent.asl")}