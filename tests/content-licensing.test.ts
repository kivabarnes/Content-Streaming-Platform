import { describe, it, expect, beforeEach } from 'vitest';

// Mock storage for content licenses and user licenses
const contentLicenses = new Map();
const userLicenses = new Map();
let nextContentId = 0;

// Mock functions to simulate contract behavior
function registerContent(owner: string, title: string, licenseType: string, expiration: number, price: number) {
  const contentId = nextContentId++;
  contentLicenses.set(contentId, { owner, title, licenseType, expiration, price });
  return contentId;
}

function updateContentLicense(contentId: number, owner: string, newLicenseType: string, newExpiration: number, newPrice: number) {
  const license = contentLicenses.get(contentId);
  if (!license) throw new Error('Content not found');
  if (license.owner !== owner) throw new Error('Not owner');
  license.licenseType = newLicenseType;
  license.expiration = newExpiration;
  license.price = newPrice;
  contentLicenses.set(contentId, license);
  return true;
}

function purchaseLicense(contentId: number, user: string) {
  const license = contentLicenses.get(contentId);
  if (!license) throw new Error('Content not found');
  if (userLicenses.has(`${user}-${contentId}`)) throw new Error('Already licensed');
  userLicenses.set(`${user}-${contentId}`, { expiration: license.expiration });
  return true;
}

function getContentLicense(contentId: number) {
  return contentLicenses.get(contentId);
}

function checkUserLicense(user: string, contentId: number) {
  const license = userLicenses.get(`${user}-${contentId}`);
  if (!license) return false;
  return license.expiration > Date.now();
}

describe('Content Licensing Contract', () => {
  beforeEach(() => {
    contentLicenses.clear();
    userLicenses.clear();
    nextContentId = 0;
  });
  
  it('should register new content', () => {
    const contentId = registerContent('owner1', 'My Content', 'standard', 1625097600, 1000);
    expect(contentId).toBe(0);
    expect(contentLicenses.size).toBe(1);
    const license = contentLicenses.get(0);
    expect(license).toBeDefined();
    expect(license.title).toBe('My Content');
  });
  
  it('should update content license', () => {
    const contentId = registerContent('owner1', 'My Content', 'standard', 1625097600, 1000);
    const result = updateContentLicense(contentId, 'owner1', 'premium', 1640995200, 2000);
    expect(result).toBe(true);
    const updatedLicense = contentLicenses.get(contentId);
    expect(updatedLicense.licenseType).toBe('premium');
    expect(updatedLicense.price).toBe(2000);
  });
  
  it('should not allow non-owner to update license', () => {
    const contentId = registerContent('owner1', 'My Content', 'standard', 1625097600, 1000);
    expect(() => updateContentLicense(contentId, 'owner2', 'premium', 1640995200, 2000)).toThrow('Not owner');
  });
  
  it('should allow users to purchase licenses', () => {
    const contentId = registerContent('owner1', 'My Content', 'standard', 1625097600, 1000);
    const result = purchaseLicense(contentId, 'user1');
    expect(result).toBe(true);
    expect(userLicenses.has('user1-0')).toBe(true);
  });
  
  it('should not allow duplicate license purchases', () => {
    const contentId = registerContent('owner1', 'My Content', 'standard', 1625097600, 1000);
    purchaseLicense(contentId, 'user1');
    expect(() => purchaseLicense(contentId, 'user1')).toThrow('Already licensed');
  });
  
  it('should correctly check user licenses', () => {
    const contentId = registerContent('owner1', 'My Content', 'standard', Date.now() + 86400000, 1000);
    purchaseLicense(contentId, 'user1');
    expect(checkUserLicense('user1', contentId)).toBe(true);
    expect(checkUserLicense('user2', contentId)).toBe(false);
  });
});
