package tools;

import cartago.*;
import java.util.*;

public class TrustCalculator extends Artifact {
    private Map<String, List<Double>> ratings;

    void init() {
        ratings = new HashMap<>();
    }

    /* collect the ratings for an agent from the interaction trust ratings */
    @OPERATION
    public void addRating(String agent, double rating) {
        ratings.computeIfAbsent(agent, k -> new ArrayList<>())
               .add(rating);
    }

    /* find the agent with highest average rating */
    @OPERATION
    public void getBestAgent(OpFeedbackParam<String> bestAgent) {
        String topAgent = null;
        double topAvg = Double.NEGATIVE_INFINITY;
        for (var e : ratings.entrySet()) {
            double sum = 0;
            for (double r : e.getValue()) sum += r;
            double avg = sum / e.getValue().size();
            if (avg > topAvg) {
                topAvg = avg;
                topAgent = e.getKey();
            }
        }
        bestAgent.set(topAgent);
    }
}
