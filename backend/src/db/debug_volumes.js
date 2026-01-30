const mongoose = require('mongoose');
require('dotenv').config({ path: '.env' });
const { Product, Volume, HasVolume } = require('../models');
const connectDB = require('./mongoose');

const debug = async () => {
    try {
        await connectDB();
        console.log('Connected to DB');

        // Get one product that has volumes
        const hasVolume = await HasVolume.findOne({});
        if (!hasVolume) {
            console.log('No HasVolume found!');
            process.exit(0);
        }

        const productId = hasVolume.product;
        console.log('Debugging Product ID:', productId);

        const product = await Product.aggregate([
            { $match: { _id: productId } },
            {
                $lookup: {
                    from: 'hasvolumes',
                    localField: '_id',
                    foreignField: 'product',
                    as: 'hasVolumes'
                }
            },
            {
                $lookup: {
                    from: 'volumes',
                    localField: 'hasVolumes.volume',
                    foreignField: '_id',
                    as: 'volumeDetails'
                }
            },
            {
                $project: {
                    name: 1,
                    status: 1,
                    conversions: 1,
                    hasVolumes: 1, // Debug raw hasVolumes
                    volumeDetails: 1, // Debug raw volumeDetails
                    volumes: {
                        $map: {
                            input: '$hasVolumes',
                            as: 'hv',
                            in: {
                                hasVolumeId: { $toString: '$$hv._id' },
                                volumeId: { $toString: '$$hv.volume' },
                                value: '$$hv.value',
                                prices: '$$hv.prices',
                                volumeName: {
                                    $arrayElemAt: [
                                        {
                                            $filter: {
                                                input: '$volumeDetails',
                                                as: 'v',
                                                cond: { $eq: ['$$v._id', '$$hv.volume'] }
                                            }
                                        },
                                        0
                                    ]
                                }
                            }
                        }
                    }
                }
            },
            {
                $addFields: {
                    volumes: {
                        $map: {
                            input: '$volumes',
                            as: 'v',
                            in: {
                                $mergeObjects: [
                                    '$$v',
                                    { volumeName: '$$v.volumeName.name' }
                                ]
                            }
                        }
                    }
                }
            }
        ]);

        console.log('Aggregation result:');
        console.log(JSON.stringify(product[0], null, 2));

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

debug();
