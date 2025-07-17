# AllianceMine Maintenance Page Implementation

## Overview
This implementation provides an automatic maintenance page that displays when AllianceMine is undergoing deployment or experiencing downtime.

## How It Works

### 1. Health Check Configuration
- **File**: `.ebextensions/loadbalancer.config`
- **Health Check Path**: `/alliancemine/begin.do`
- **Behavior**: ALB checks this endpoint every 30 seconds
- **Threshold**: 3 consecutive failures trigger unhealthy state

### 2. Maintenance Page
- **File**: `.ebextensions/cloudfront-maintenance.config`
- **Location**: `/var/www/html/maintenance.html`
- **Content**: Professional maintenance message with:
  - Alliance Genome Resources logo
  - Expected restoration time: 1 hour or less
  - Contact information: help@alliancegenome.org
  - Professional, non-embellished language

### 3. Nginx Configuration
- **File**: `.platform/nginx/conf.d/maintenance.conf`
- **Behavior**: Serves maintenance page for HTTP errors 502, 503, 504
- **Caching**: Disabled to ensure real-time updates

## Deployment Flow

1. **EBS Deployment Starts**
   - Containers stop/restart during deployment
   - Health check `/alliancemine/begin.do` begins failing

2. **Automatic Maintenance Mode**
   - ALB detects unhealthy instances
   - Nginx serves maintenance page for failed upstream connections
   - Users see professional maintenance message

3. **Service Restoration**
   - Containers finish starting up
   - Health check `/alliancemine/begin.do` starts passing
   - ALB routes traffic back to healthy instances
   - Maintenance page automatically disappears

## Files Modified/Created

### Modified Files:
- `.ebextensions/loadbalancer.config` - Updated health check path and ALB configuration

### New Files:
- `.ebextensions/cloudfront-maintenance.config` - Maintenance page deployment
- `.platform/nginx/conf.d/maintenance.conf` - Nginx error page configuration
- `README_MAINTENANCE.md` - This documentation

## Testing

To test the maintenance page:
1. Deploy these changes to staging environment
2. Manually stop the application containers
3. Verify maintenance page appears at alliancemine URL
4. Restart containers and verify normal site returns

## Configuration Details

### Health Check Settings:
- **Interval**: 30 seconds
- **Timeout**: 5 seconds
- **Healthy Threshold**: 2 consecutive successes
- **Unhealthy Threshold**: 3 consecutive failures

### Maintenance Page Features:
- ✅ Professional appearance matching Alliance branding
- ✅ Clear explanation of maintenance status
- ✅ Realistic timeline (1 hour or less)
- ✅ Contact information for issues
- ✅ No caching to ensure real-time updates

## Benefits

1. **Automatic Operation**: No manual intervention required
2. **User Experience**: Professional message instead of error pages
3. **Monitoring Compatible**: Works with existing UptimeRobot checks
4. **Infrastructure Leveraged**: Uses existing ALB and health check systems