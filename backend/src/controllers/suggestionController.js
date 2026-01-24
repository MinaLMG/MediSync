const AppSuggestion = require('../models/AppSuggestion');

exports.createSuggestion = async (req, res) => {
    try {
        const { content } = req.body;
        
        if (!content) {
            return res.status(400).json({ success: false, message: 'Content is required' });
        }

        const suggestion = new AppSuggestion({
            pharmacy: req.user.pharmacy,
            user: req.user._id,
            content
        });

        await suggestion.save();
        res.status(201).json({ success: true, data: suggestion });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

exports.markAsSeen = async (req, res) => {
    try {
        const suggestion = await AppSuggestion.findByIdAndUpdate(
            req.params.id,
            { seen: true },
            { new: true }
        );

        if (!suggestion) {
            return res.status(404).json({ success: false, message: 'Suggestion not found' });
        }

        res.status(200).json({ success: true, data: suggestion });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

exports.getAllSuggestions = async (req, res) => {
    try {
        const suggestions = await AppSuggestion.find()
            .populate('pharmacy', 'name')
            .populate('user', 'name')
            .sort({ createdAt: -1 });
            
        res.status(200).json({ success: true, count: suggestions.length, data: suggestions });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};
