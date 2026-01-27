const express = require('express');
const router = express.Router();
const participationController = require('../controllers/participationController');
const auth = require('../middleware/authMiddleware');
const role = require('../middleware/roleMiddleware');

// Customer Routes
router.post('/join/:campaignId',
    auth,
    role(['customer']),
    participationController.joinCampaign
);

router.get('/my',
    auth,
    role(['customer']),
    participationController.getMyParticipations
);

// Win/Complete Route (Can be restricted to internal or business if needed, 
// here kept for manual trigger as requested)
router.post('/win/:id',
    auth,
    participationController.completeCampaign
);

module.exports = router;
