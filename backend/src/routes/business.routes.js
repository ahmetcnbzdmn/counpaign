const express = require('express');
const router = express.Router();
const businessController = require('../controllers/businessController');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

// Base path: /api/business
// All routes require authentication and 'business' role
router.use(authMiddleware);
router.use(roleMiddleware(['business']));

router.post('/terminals', businessController.createTerminal);
router.get('/terminals', businessController.getTerminals);

module.exports = router;
