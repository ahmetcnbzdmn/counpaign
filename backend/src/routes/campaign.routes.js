const express = require('express');
const router = express.Router();
const campaignController = require('../controllers/campaignController');
const auth = require('../middleware/authMiddleware');
const role = require('../middleware/roleMiddleware');

// Public route: Get all campaigns for a specific business
router.get('/business/:businessId', campaignController.getCampaignsByBusiness);

// Public route: Get ALL campaigns (Global)
router.get('/', campaignController.getAllCampaigns);

// Protected routes (Business only)
router.post('/',
    auth,
    role(['business']),
    campaignController.createCampaign
);

router.patch('/:id',
    auth,
    role(['business']),
    campaignController.updateCampaign
);

router.delete('/:id',
    auth,
    role(['business']),
    campaignController.deleteCampaign
);

module.exports = router;
