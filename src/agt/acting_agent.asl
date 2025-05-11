// acting agent

/* Initial beliefs and rules */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://ci.mines-stetienne.fr/kg/ontology#PhantomX
robot_td("https://raw.githubusercontent.com/Interactions-HSG/example-tds/main/tds/leubot1.ttl").

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start
    :  true
    <-  .print("Hello world");
    .

/* 
 * Plan for reacting to the addition of the belief organization_deployed(OrgName)
 * Triggering event: addition of belief organization_deployed(OrgName)
 * Context: true (the plan is always applicable)
 * Body: joins the workspace and the organization named OrgName
*/
@organization_deployed_plan
+organization_deployed(OrgName)
    :  true
    <-  .print("Notified about organization deployment of ", OrgName);
        // joins the workspace
        joinWorkspace(OrgName);
        // looks up for, and focuses on the OrgArtifact that represents the organization
        lookupArtifact(OrgName, OrgId);
        focus(OrgId);
    .

/* 
 * Plan for reacting to the addition of the belief available_role(Role)
 * Triggering event: addition of belief available_role(Role)
 * Context: true (the plan is always applicable)
 * Body: adopts the role Role
*/
@available_role_plan
+available_role(Role)
    :  true
    <-  .print("Adopting the role of ", Role);
        adoptRole(Role);
    .

/* 
 * Plan for reacting to the addition of the belief interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
 * Triggering event: addition of belief interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
 * Context: true (the plan is always applicable)
 * Body: prints new interaction trust rating (relevant from Task 1 and on)
*/
+interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
    :  true
    <-  .print("Interaction Trust Rating: (", TargetAgent, ", ", SourceAgent, ", ", MessageContent, ", ", ITRating, ")");
    .

/* 
 * Plan for reacting to the addition of the certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
 * Triggering event: addition of belief certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new certified reputation rating (relevant from Task 3 and on)
*/
+certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
    :  true
    <-  .print("Certified Reputation Rating: (", CertificationAgent, ", ", SourceAgent, ", ", MessageContent, ", ", CRRating, ")");
    .

/* 
 * Plan for reacting to the addition of the witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating)
 * Triggering event: addition of belief witness_reputation(WitnessAgent, SourceAgent,, MessageContent, WRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new witness reputation rating (relevant from Task 5 and on)
*/
+witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating)
    :  true
    <-  .print("Witness Reputation Rating: (", WitnessAgent, ", ", SourceAgent, ", ", MessageContent, ", ", WRRating, ")");
    .

/* 
 * Task 1 & 3 & 4: select the reading from the agent with highest rating
 *  using RatingCalculator
 */
@select_reading_plan
+!select_reading(TempPairs, Celsius)
    :  true
    <-
        .print("Computing ratings to select best agent");
        makeArtifact("rateCalc", "tools.RatingCalculator", [], CalcId);

        // Add IT (Task 1)
        .findall([A,R], interaction_trust(acting_agent,A,_,R), Pairs);
        for(.member([A,R], Pairs)) {
            addRating(A, R)[artifact_id(CalcId)];
        };

        // Add CR and WR (Task 3 and 4)
        .findall(cert, .all_names(Agents) & .member(certification_agent, Agents), CertExists);
        if (.length(CertExists) > 0) {
            // Add all certification reputation ratings (Task 3)
            for(.member([A,T], TempPairs) & certified_reputation(certification_agent, A, _, CR)) {
                addCertifiedRating(A, CR)[artifact_id(CalcId)];
            };
            
            // Add all witness reputation ratings (Task 4)
            .findall([A,R], witness_reputation(_, A, _, R), WRPairs);
            for(.member([A,R], WRPairs)) {
                addWitnessRating(A, R)[artifact_id(CalcId)];
            };
        }

        getBestAgent(BestAgent)[artifact_id(CalcId)];
        .print("Best agent = ", BestAgent);

        // Change agent to string
        .findall([StrA,T], ( temperature(T)[source(A)] & .term2string(A, StrA) ), StrTemps);
  
        .member([BestAgent, Celsius], StrTemps);
        .print("Temperature from best agent = ", Celsius);
    .
/* 
 * Plan for reacting to the addition of the goal !manifest_temperature
 * Triggering event: addition of goal !manifest_temperature
 * Context: the agent believes that there is a temperature in Celsius and
 * that a WoT TD of an onto:PhantomX is located at Location
 * Body: converts the temperature from Celsius to binary degrees that are compatible with the 
 * movement of the robotic arm. Then, manifests the temperature with the robotic arm
*/
@manifest_temperature_plan 
+!manifest_temperature
    :  robot_td(Location)
    <-  // Collect all temperature readings and their sources
        .findall([A,T], temperature(T)[source(A)], TempPairs);
        .print("collected temp and agent pairs = ", TempPairs);

        // if certification agent present (Task 3)
        .findall(cert, .all_names(Agents) & .member(certification_agent, Agents), CertExists);
        if (.length(CertExists) > 0) {
            // Task 3: Request certified reputations from readers
            for(.member([A,Temp], TempPairs)) {
                .send(A, askOne, certified_reputation(certification_agent, A, _, CR), Response);
                if (Response \== false) {
                    .print("Response from ", A, ": ", Response);
                    +Response;
                }
            }
            
            // Task 4: Request witness reputation ratings from all temperature readers (asks A about its witness rating of B)
            for(.member([A,_], TempPairs)) {
                for(.member([B,_], TempPairs)) {
                    if (A \== B) {
                        .send(A, askOne, witness_reputation(A, B, _, WR), WRResponse);
                        if (WRResponse \== false) {
                            .print("Witness rating from ", A, " about ", B, ": ", WRResponse);
                            +WRResponse;
                        }
                    }
                }
            }
        }

        !select_reading(TempPairs, SelectedTemp);

        // Continue with manifesting the selected temperature
        .print("I will manifest the temperature: ", SelectedTemp);
        convert(SelectedTemp, -20.00, 20.00, 200.00, 830.00, Degrees)[artifact_id(ConverterId)]; // converts Celsius to binary degrees based on the input scale
        .print("Temperature Manifesting (moving robotic arm to): ", Degrees);

        /* 
         * If you want to test with the real robotic arm, 
         * follow the instructions here: https://github.com/HSG-WAS-SS24/exercise-8/blob/main/README.md#test-with-the-real-phantomx-reactor-robot-arm
         */
        // creates a ThingArtifact based on the TD of the robotic arm
        makeArtifact("leubot1", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Location, true], Leubot1Id); 
        
        // sets the API key for controlling the robotic arm as an authenticated user
        //setAPIKey("77d7a2250abbdb59c6f6324bf1dcddb5")[artifact_id(Leubot1Id)];

        // invokes the action onto:SetWristAngle for manifesting the temperature with the wrist of the robotic arm
        invokeAction("https://ci.mines-stetienne.fr/kg/ontology#SetWristAngle", ["https://www.w3.org/2019/wot/json-schema#IntegerSchema"], [Degrees])[artifact_id(Leubot1Id)];
    .

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }

/* Import interaction trust ratings */
{ include("inc/interaction_trust_ratings.asl") }
