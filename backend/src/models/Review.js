const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
    reviewerPharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
    reviewedPharmacy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Pharmacy',
        required: true
    },
    transaction: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Transaction',
        required: true
    },
    rating: {
        type: Number,
        required: true,
        min: 1,
        max: 5
    },
    comment: {
        type: String,
        trim: true
    },
    response: {
        type: String,
        trim: true
    }
}, {
    timestamps: true
});

// Ensure one review per transaction per pharmacy
reviewSchema.index({ reviewerPharmacy: 1, transaction: 1 }, { unique: true });
reviewSchema.index({ reviewedPharmacy: 1 });

// Update pharmacy rating after review is saved
reviewSchema.post('save', async function() {
    const Review = this.constructor;
    const Pharmacy = mongoose.model('Pharmacy');
    
    // Calculate average rating for the reviewed pharmacy
    const stats = await Review.aggregate([
        { $match: { reviewedPharmacy: this.reviewedPharmacy } },
        { $group: { _id: null, avgRating: { $avg: '$rating' } } }
    ]);
    
    if (stats.length > 0) {
        await Pharmacy.findByIdAndUpdate(this.reviewedPharmacy, {
            rating: Math.round(stats[0].avgRating * 10) / 10 // Round to 1 decimal
        });
    }
});

module.exports = mongoose.model('Review', reviewSchema);
