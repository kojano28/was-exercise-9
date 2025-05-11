package tools;

import cartago.*;
import java.util.*;

public class RatingCalculator extends Artifact {
    private Map<String, List<Double>> trustRatings;
    private Map<String, Double> certifiedRatings;
    private Map<String, List<Double>> witnessRatings;

    void init() {
        trustRatings = new HashMap<>();
        certifiedRatings = new HashMap<>();
                witnessRatings = new HashMap<>();
    }

    /*Task 1: addRating(agent, itRating) */
    @OPERATION
    public void addRating(String agent, double rating) {
        trustRatings.computeIfAbsent(agent, k -> new ArrayList<>()).add(rating);
    }

    /* Task 3: addCertifiedRating(agent, CRRatingRating) */
    @OPERATION
    public void addCertifiedRating(String agent, double rating) {
        certifiedRatings.put(agent, rating);
    }

    /* Task 4: addWitnessRating(agent, wrRating) */
    @OPERATION
    public void addWitnessRating(String agent, double rating) {
        witnessRatings.computeIfAbsent(agent, k -> new ArrayList<>()).add(rating);
    }

    /**
     * Returns the agent with the highest trust score.
     * For Task 1: Uses only interaction trust
     * For Task 3: Uses combined IT and CR ratings 
     * For Task 4: Uses combined IT, CR, and WR ratings 
     */
    @OPERATION
    public void getBestAgent(OpFeedbackParam<String> bestAgent) {
        String topAgent = null;
        double topScore = Double.NEGATIVE_INFINITY;
        boolean hasCertifiedRatings = !certifiedRatings.isEmpty();
        boolean hasWitnessRatings = !witnessRatings.isEmpty();

        for (String agent : trustRatings.keySet()) {
            // Task 1: Calculate IT
            List<Double> list = trustRatings.get(agent);
            double sum = 0;
            for (double r : list) sum += r;
            double IT_AVG = sum / list.size();
            
            double finalScore;
            
            if (hasWitnessRatings && hasCertifiedRatings) {
                // Task 4: Combined IT, CR, and WR
                double CRRating = certifiedRatings.getOrDefault(agent, 0.0);
                
                // Calculate witness reputation average 
                double wrAvg = 0.0;
                List<Double> wrList = witnessRatings.get(agent);
                if (wrList != null && !wrList.isEmpty()) {
                    double wrSum = 0;
                    for (double r : wrList) wrSum += r;
                    wrAvg = wrSum / wrList.size();
                }
                
                // compute IT_CR_WR
                finalScore = (1.0/3.0) * IT_AVG + (1.0/3.0) * CRRating + (1.0/3.0) * wrAvg;
            } else if (hasCertifiedRatings) {
                // Task 3: Combined IT and CR = IT_CR
                double CRRating = certifiedRatings.getOrDefault(agent, 0.0);
                finalScore = 0.5 * IT_AVG + 0.5 * CRRating;
            } else {
                // Task 1: Only IT
                finalScore = IT_AVG;
            }

            if (finalScore > topScore) {
                topScore = finalScore;
                topAgent = agent;
            }
        }

        bestAgent.set(topAgent);
    }
}
