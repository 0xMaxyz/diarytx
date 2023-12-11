// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Enums {
    enum DiaryVisibility {
        Private,
        Public
    }

    enum ProfieVisibility {
        Private,
        Public
    }

    enum TokenType {
        ProfileToken,
        FollowerToken,
        DiaryToken
    }

    enum AiAssistance {
        CoverGeneration,
        MoodDetection,
        MoodAnalysis,
        MusicRecommendation,
        MovieRecommendation,
        BookRecommendation
    }

    enum Mood {
        Angry,
        Anxious,
        Bored,
        Calm,
        Confused,
        Disappointed,
        Energetic,
        Excited,
        Grateful,
        Happy,
        Hopeful,
        Insecure,
        Jealous,
        Lonely,
        Motivated,
        Overwhelmed,
        Peaceful,
        Proud,
        Reflective,
        Sad
    }
}
