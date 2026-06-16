const OpenAI = require('openai');
const { supabase, uploadFile } = require('../config/supabase');
const { ApiError, asyncHandler } = require('../middleware/errorMiddleware');
const { processFile } = require('../middleware/uploadMiddleware');
const constants = require('../config/constants');
const logger = require('../utils/logger');

// Initialize Groq client (uses OpenAI SDK for compatibility)
let groqClient = null;

const getGroqClient = () => {
  if (!groqClient) {
    if (!process.env.GROQ_API_KEY) {
      throw new ApiError(503, 'AI service is not configured. Please contact administrator.');
    }
    groqClient = new OpenAI({
      apiKey: process.env.GROQ_API_KEY,
      baseURL: 'https://api.groq.com/openai/v1',
    });
  }
  return groqClient;
};

// System prompt for farming assistant
const FARMING_SYSTEM_PROMPT = constants.ai.systemPrompt;

/**
 * @desc    Send message to AI assistant
 * @route   POST /api/v1/ai/chat
 */
const chat = asyncHandler(async (req, res) => {
  const { message, sessionId } = req.body;
  const userId = req.user.id;

  // Get or create session
  let session;
  if (sessionId) {
    const { data } = await supabase
      .from('ai_chat_sessions')
      .select('*')
      .eq('id', sessionId)
      .eq('user_id', userId)
      .single();
    session = data;
  }

  if (!session) {
    const { data, error } = await supabase
      .from('ai_chat_sessions')
      .insert({
        user_id: userId,
        title: message.substring(0, 50),
        messages: [],
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) {
      logger.error('Create session error:', error);
      throw new ApiError(400, 'Failed to create chat session');
    }
    session = data;
  }

  // Build conversation history
  const messages = [
    { role: 'system', content: FARMING_SYSTEM_PROMPT },
    ...(session.messages || []),
    { role: 'user', content: message },
  ];

  // Call Groq API
  try {
    const completion = await getGroqClient().chat.completions.create({
      model: constants.ai.model,
      messages,
      max_tokens: constants.ai.maxTokens,
      temperature: constants.ai.temperature,
    });

    const aiResponse = completion.choices[0].message.content;

    // Update session with new messages
    const updatedMessages = [
      ...(session.messages || []),
      { role: 'user', content: message, timestamp: new Date().toISOString() },
      { role: 'assistant', content: aiResponse, timestamp: new Date().toISOString() },
    ];

    await supabase
      .from('ai_chat_sessions')
      .update({
        messages: updatedMessages,
        updated_at: new Date().toISOString(),
      })
      .eq('id', session.id);

    // Track AI usage
    await trackAIUsage(userId, 'chat', completion.usage?.total_tokens || 0);

    res.json({
      success: true,
      data: {
        sessionId: session.id,
        message: aiResponse,
        usage: {
          promptTokens: completion.usage?.prompt_tokens,
          completionTokens: completion.usage?.completion_tokens,
          totalTokens: completion.usage?.total_tokens,
        },
      },
    });
  } catch (error) {
    logger.error('Groq chat error:', error);
    throw new ApiError(500, 'Failed to get AI response');
  }
});

/**
 * @desc    Analyze crop/plant image
 * @route   POST /api/v1/ai/analyze-image
 */
const analyzeImage = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { question } = req.body;

  if (!req.file) {
    throw new ApiError(400, 'No image uploaded');
  }

  // Upload image to storage
  const fileInfo = processFile(req.file, 'ai-images');
  const uploadResult = await uploadFile(
    fileInfo.buffer,
    'ai-images',
    fileInfo.filePath,
    fileInfo.contentType
  );

  if (!uploadResult.success) {
    throw new ApiError(400, 'Failed to upload image');
  }

  // Convert image to base64
  const base64Image = req.file.buffer.toString('base64');
  const mimeType = req.file.mimetype;

  try {
    const completion = await getGroqClient().chat.completions.create({
      model: constants.ai.visionModel,
      messages: [
        {
          role: 'system',
          content: `You are an agricultural expert helping Ugandan farmers. Analyze the image and provide helpful insights about:
- Crop/plant identification
- Health assessment
- Potential diseases or pests
- Care recommendations
Be specific and practical in your advice.`,
        },
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: {
                url: `data:${mimeType};base64,${base64Image}`,
              },
            },
            {
              type: 'text',
              text: question || 'Please analyze this image and provide insights about what you see.',
            },
          ],
        },
      ],
      max_tokens: 1000,
    });

    const analysis = completion.choices[0].message.content;

    // Track usage
    await trackAIUsage(userId, 'image_analysis', completion.usage?.total_tokens || 0);

    res.json({
      success: true,
      data: {
        imageUrl: uploadResult.publicUrl,
        analysis,
      },
    });
  } catch (error) {
    logger.error('Groq vision error:', error);
    throw new ApiError(500, 'Failed to analyze image');
  }
});

/**
 * @desc    Get user's chat sessions
 * @route   GET /api/v1/ai/sessions
 */
const getChatSessions = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const { data, error } = await supabase
    .from('ai_chat_sessions')
    .select('id, title, created_at, updated_at')
    .eq('user_id', userId)
    .order('updated_at', { ascending: false })
    .limit(50);

  if (error) {
    logger.error('Get sessions error:', error);
    throw new ApiError(400, 'Failed to fetch chat sessions');
  }

  res.json({
    success: true,
    data,
  });
});

/**
 * @desc    Get chat session by ID
 * @route   GET /api/v1/ai/sessions/:sessionId
 */
const getChatSession = asyncHandler(async (req, res) => {
  const { sessionId } = req.params;
  const userId = req.user.id;

  const { data, error } = await supabase
    .from('ai_chat_sessions')
    .select('*')
    .eq('id', sessionId)
    .eq('user_id', userId)
    .single();

  if (error || !data) {
    throw new ApiError(404, 'Session not found');
  }

  res.json({
    success: true,
    data,
  });
});

/**
 * @desc    Delete chat session
 * @route   DELETE /api/v1/ai/sessions/:sessionId
 */
const deleteChatSession = asyncHandler(async (req, res) => {
  const { sessionId } = req.params;
  const userId = req.user.id;

  const { error } = await supabase
    .from('ai_chat_sessions')
    .delete()
    .eq('id', sessionId)
    .eq('user_id', userId);

  if (error) {
    logger.error('Delete session error:', error);
    throw new ApiError(400, 'Failed to delete session');
  }

  res.json({
    success: true,
    message: 'Session deleted',
  });
});

/**
 * @desc    Get detailed crop analysis
 * @route   POST /api/v1/ai/crop-analysis
 */
const getCropAnalysis = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { cropName, region, issues } = req.body;

  if (!cropName) {
    throw new ApiError(400, 'Crop name is required');
  }

  const prompt = `Provide detailed analysis for growing ${cropName} in ${region || 'Uganda'}:

1. **Best Growing Conditions**: Soil type, climate, water requirements
2. **Planting Guide**: Best time to plant, spacing, depth
3. **Care Instructions**: Watering schedule, fertilization, pruning
4. **Common Pests & Diseases**: Identification and organic solutions
5. **Harvest Information**: When and how to harvest
6. **Market Insights**: Expected yields and current market trends in Uganda

${issues ? `Also address these specific issues: ${issues}` : ''}

Provide practical advice specific to small-scale farming in Uganda.`;

  try {
    const completion = await getGroqClient().chat.completions.create({
      model: constants.ai.model,
      messages: [
        { role: 'system', content: FARMING_SYSTEM_PROMPT },
        { role: 'user', content: prompt },
      ],
      max_tokens: 1500,
    });

    const analysis = completion.choices[0].message.content;

    await trackAIUsage(userId, 'crop_analysis', completion.usage?.total_tokens || 0);

    res.json({
      success: true,
      data: {
        cropName,
        region: region || 'Uganda',
        analysis,
      },
    });
  } catch (error) {
    logger.error('Crop analysis error:', error);
    throw new ApiError(500, 'Failed to get crop analysis');
  }
});

/**
 * @desc    Get personalized farming tips
 * @route   GET /api/v1/ai/farming-tips
 */
const getFarmingTips = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { region, season, crops } = req.query;

  const currentMonth = new Date().toLocaleString('default', { month: 'long' });
  
  const prompt = `Provide 5 timely farming tips for ${currentMonth} in ${region || 'Uganda'}:

${crops ? `Focus on these crops: ${crops}` : 'Include tips for common Ugandan crops like matooke, beans, maize, and coffee.'}

For each tip, provide:
1. Title (short and catchy)
2. Brief explanation (2-3 sentences)
3. Action items

Consider current season: ${season || 'normal season'}
Make tips practical and actionable for small-scale farmers.`;

  try {
    const completion = await getGroqClient().chat.completions.create({
      model: constants.ai.model,
      messages: [
        { role: 'system', content: FARMING_SYSTEM_PROMPT },
        { role: 'user', content: prompt },
      ],
      max_tokens: 1000,
    });

    const tips = completion.choices[0].message.content;

    await trackAIUsage(userId, 'farming_tips', completion.usage?.total_tokens || 0);

    res.json({
      success: true,
      data: {
        month: currentMonth,
        region: region || 'Uganda',
        tips,
      },
    });
  } catch (error) {
    logger.error('Farming tips error:', error);
    throw new ApiError(500, 'Failed to get farming tips');
  }
});

/**
 * @desc    Get market predictions for crops
 * @route   GET /api/v1/ai/market-predictions
 */
const getMarketPredictions = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { crops, region, timeframe = '3 months' } = req.query;

  const cropList = crops || 'maize, beans, coffee, matooke';
  
  const prompt = `Provide market predictions for the following crops in ${region || 'Uganda'} for the next ${timeframe}:

Crops: ${cropList}

For each crop, analyze:
1. **Current Price Trend**: Is it rising, falling, or stable?
2. **Predicted Price Movement**: Expected direction and approximate percentage
3. **Best Time to Sell**: Recommended timing
4. **Market Factors**: What's influencing prices
5. **Recommendation**: Buy, sell, or hold advice

Note: These are predictions based on typical seasonal patterns and market knowledge. Actual prices may vary.`;

  try {
    const completion = await getGroqClient().chat.completions.create({
      model: constants.ai.model,
      messages: [
        { role: 'system', content: FARMING_SYSTEM_PROMPT },
        { role: 'user', content: prompt },
      ],
      max_tokens: 1200,
    });

    const predictions = completion.choices[0].message.content;

    await trackAIUsage(userId, 'market_predictions', completion.usage?.total_tokens || 0);

    res.json({
      success: true,
      data: {
        crops: cropList,
        region: region || 'Uganda',
        timeframe,
        predictions,
        disclaimer: 'These predictions are for informational purposes only and should not be considered financial advice.',
      },
    });
  } catch (error) {
    logger.error('Market predictions error:', error);
    throw new ApiError(500, 'Failed to get market predictions');
  }
});

/**
 * @desc    Get weather-based farming recommendations
 * @route   GET /api/v1/ai/weather-recommendations
 */
const getWeatherRecommendations = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { region, weatherCondition, crops } = req.query;

  const prompt = `Given the current weather condition (${weatherCondition || 'normal'}) in ${region || 'Uganda'}, provide farming recommendations:

${crops ? `For these crops: ${crops}` : 'For common Ugandan crops'}

Include:
1. **Immediate Actions**: What farmers should do now
2. **Crop Protection**: How to protect crops from weather effects
3. **Irrigation Advice**: Watering recommendations
4. **Harvesting Guidance**: If applicable
5. **Preparation for Coming Days**: What to expect and prepare for

Keep advice practical for small-scale farmers with limited resources.`;

  try {
    const completion = await getGroqClient().chat.completions.create({
      model: constants.ai.model,
      messages: [
        { role: 'system', content: FARMING_SYSTEM_PROMPT },
        { role: 'user', content: prompt },
      ],
      max_tokens: 800,
    });

    const recommendations = completion.choices[0].message.content;

    await trackAIUsage(userId, 'weather_recommendations', completion.usage?.total_tokens || 0);

    res.json({
      success: true,
      data: {
        region: region || 'Uganda',
        weatherCondition: weatherCondition || 'normal',
        recommendations,
      },
    });
  } catch (error) {
    logger.error('Weather recommendations error:', error);
    throw new ApiError(500, 'Failed to get weather recommendations');
  }
});

/**
 * @desc    Identify pests from image
 * @route   POST /api/v1/ai/pest-identification
 */
const identifyPest = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  if (!req.file) {
    throw new ApiError(400, 'No image uploaded');
  }

  const base64Image = req.file.buffer.toString('base64');
  const mimeType = req.file.mimetype;

  try {
    const completion = await getGroqClient().chat.completions.create({
      model: constants.ai.visionModel,
      messages: [
        {
          role: 'system',
          content: `You are an agricultural pest identification expert for Uganda. Analyze images to identify pests and provide control methods.`,
        },
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: {
                url: `data:${mimeType};base64,${base64Image}`,
              },
            },
            {
              type: 'text',
              text: `Identify any pests in this image and provide:
1. **Pest Name**: Common and scientific name
2. **Description**: Appearance and behavior
3. **Damage Caused**: What harm it causes to crops
4. **Organic Control Methods**: Natural remedies
5. **Chemical Control**: If necessary, with safety precautions
6. **Prevention**: How to prevent future infestations`,
            },
          ],
        },
      ],
      max_tokens: 1000,
    });

    const analysis = completion.choices[0].message.content;

    await trackAIUsage(userId, 'pest_identification', completion.usage?.total_tokens || 0);

    res.json({
      success: true,
      data: { analysis },
    });
  } catch (error) {
    logger.error('Pest identification error:', error);
    throw new ApiError(500, 'Failed to identify pest');
  }
});

/**
 * @desc    Diagnose plant disease from image
 * @route   POST /api/v1/ai/disease-diagnosis
 */
const diagnosePlantDisease = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  if (!req.file) {
    throw new ApiError(400, 'No image uploaded');
  }

  const base64Image = req.file.buffer.toString('base64');
  const mimeType = req.file.mimetype;

  try {
    const completion = await getGroqClient().chat.completions.create({
      model: constants.ai.visionModel,
      messages: [
        {
          role: 'system',
          content: `You are a plant pathologist specializing in diseases affecting crops in Uganda. Diagnose plant diseases from images and provide treatment advice.`,
        },
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: {
                url: `data:${mimeType};base64,${base64Image}`,
              },
            },
            {
              type: 'text',
              text: `Diagnose any plant disease visible in this image:
1. **Disease Name**: Common and scientific name
2. **Symptoms**: What you observe
3. **Cause**: Fungal, bacterial, viral, or environmental
4. **Treatment Options**: Both organic and conventional
5. **Recovery Prognosis**: Can the plant recover?
6. **Prevention**: How to prevent spread and future occurrences`,
            },
          ],
        },
      ],
      max_tokens: 1000,
    });

    const diagnosis = completion.choices[0].message.content;

    await trackAIUsage(userId, 'disease_diagnosis', completion.usage?.total_tokens || 0);

    res.json({
      success: true,
      data: { diagnosis },
    });
  } catch (error) {
    logger.error('Disease diagnosis error:', error);
    throw new ApiError(500, 'Failed to diagnose disease');
  }
});

/**
 * @desc    Get AI usage statistics
 * @route   GET /api/v1/ai/usage
 */
const getUsageStats = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const { data, error } = await supabase
    .from('ai_usage')
    .select('*')
    .eq('user_id', userId)
    .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString());

  if (error) {
    logger.error('Get usage stats error:', error);
    throw new ApiError(400, 'Failed to fetch usage stats');
  }

  // Aggregate by feature
  const usageByFeature = {};
  let totalTokens = 0;

  for (const record of data) {
    if (!usageByFeature[record.feature]) {
      usageByFeature[record.feature] = { count: 0, tokens: 0 };
    }
    usageByFeature[record.feature].count++;
    usageByFeature[record.feature].tokens += record.tokens_used;
    totalTokens += record.tokens_used;
  }

  res.json({
    success: true,
    data: {
      period: 'Last 30 days',
      totalRequests: data.length,
      totalTokens,
      usageByFeature,
    },
  });
});

/**
 * Helper function to track AI usage
 */
const trackAIUsage = async (userId, feature, tokensUsed) => {
  try {
    await supabase.from('ai_usage').insert({
      user_id: userId,
      feature,
      tokens_used: tokensUsed,
      created_at: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('Track AI usage error:', error);
  }
};

module.exports = {
  chat,
  analyzeImage,
  getChatSessions,
  getChatSession,
  deleteChatSession,
  getCropAnalysis,
  getFarmingTips,
  getMarketPredictions,
  getWeatherRecommendations,
  identifyPest,
  diagnosePlantDisease,
  getUsageStats,
};
