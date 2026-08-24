const fs = require('fs');
const path = require('path');

const {
  createRunOncePlugin,
  withEntitlementsPlist,
  withInfoPlist,
  withXcodeProject,
} = require('@expo/config-plugins');

const pkg = require('../package.json');

const TARGET_NAME = 'KoltKeyboardExtension';
const EXTENSION_DIRECTORY = TARGET_NAME;

function findTarget(project, name) {
  const targets = project.pbxNativeTargetSection();
  for (const [uuid, target] of Object.entries(targets)) {
    if (uuid.endsWith('_comment')) continue;
    const targetName = String(target.name || '').replaceAll('"', '');
    if (targetName === name) return { uuid, target };
  }
  return null;
}

function configureTargetBuildSettings(project, target, bundleIdentifier, marketingVersion) {
  const configurationList = project.pbxXCConfigurationList()[target.buildConfigurationList];
  const configurations = project.pbxXCBuildConfigurationSection();

  for (const entry of configurationList.buildConfigurations) {
    const settings = configurations[entry.value].buildSettings;
    settings.APPLICATION_EXTENSION_API_ONLY = 'YES';
    settings.CLANG_ENABLE_MODULES = 'YES';
    settings.CODE_SIGN_ENTITLEMENTS = `"${EXTENSION_DIRECTORY}/${TARGET_NAME}.entitlements"`;
    settings.CURRENT_PROJECT_VERSION = '1';
    settings.GENERATE_INFOPLIST_FILE = 'NO';
    settings.INFOPLIST_FILE = `"${EXTENSION_DIRECTORY}/Info.plist"`;
    settings.IPHONEOS_DEPLOYMENT_TARGET = '16.4';
    settings.MARKETING_VERSION = marketingVersion;
    settings.PRODUCT_BUNDLE_IDENTIFIER = `"${bundleIdentifier}"`;
    settings.PRODUCT_NAME = `"${TARGET_NAME}"`;
    settings.SKIP_INSTALL = 'YES';
    settings.SWIFT_VERSION = '5.0';
    settings.TARGETED_DEVICE_FAMILY = '"1,2"';
  }
}

function addExtensionTarget(project, bundleIdentifier, marketingVersion) {
  let extensionTarget = findTarget(project, TARGET_NAME);
  if (!extensionTarget) {
    const added = project.addTarget(
      TARGET_NAME,
      'app_extension',
      EXTENSION_DIRECTORY,
      bundleIdentifier
    );
    extensionTarget = { uuid: added.uuid, target: added.pbxNativeTarget };
    project.addBuildPhase(
      [`${EXTENSION_DIRECTORY}/KeyboardViewController.swift`],
      'PBXSourcesBuildPhase',
      'Sources',
      extensionTarget.uuid
    );
    project.addBuildPhase([], 'PBXFrameworksBuildPhase', 'Frameworks', extensionTarget.uuid);
    project.addBuildPhase([], 'PBXResourcesBuildPhase', 'Resources', extensionTarget.uuid);
  }

  configureTargetBuildSettings(project, extensionTarget.target, bundleIdentifier, marketingVersion);
}

function copyExtensionFiles(projectRoot, appGroupIdentifier, displayName) {
  const destination = path.join(projectRoot, EXTENSION_DIRECTORY);
  const templates = path.join(__dirname, 'ios');
  fs.mkdirSync(destination, { recursive: true });
  fs.copyFileSync(
    path.join(templates, 'KeyboardViewController.swift'),
    path.join(destination, 'KeyboardViewController.swift')
  );

  const infoPlist = fs
    .readFileSync(path.join(templates, 'Info.plist'), 'utf8')
    .replaceAll('__APP_GROUP__', appGroupIdentifier)
    .replaceAll('__DISPLAY_NAME__', displayName);
  fs.writeFileSync(path.join(destination, 'Info.plist'), infoPlist);

  const entitlements = fs
    .readFileSync(path.join(templates, 'KoltKeyboardExtension.entitlements'), 'utf8')
    .replaceAll('__APP_GROUP__', appGroupIdentifier);
  fs.writeFileSync(path.join(destination, `${TARGET_NAME}.entitlements`), entitlements);
}

function withKoltKeyboard(config, props) {
  if (
    !props ||
    typeof props.appGroupIdentifier !== 'string' ||
    !props.appGroupIdentifier.startsWith('group.')
  ) {
    throw new Error(
      'kolt-keyboard requires an appGroupIdentifier beginning with "group." in app.json.'
    );
  }

  const extensionBundleIdentifier =
    props.extensionBundleIdentifier || `${config.ios?.bundleIdentifier}.${TARGET_NAME}`;
  const displayName = props.displayName || 'Kolt Keyboard';
  const marketingVersion = config.version || '1.0.0';

  config = withInfoPlist(config, (infoConfig) => {
    infoConfig.modResults.KoltKeyboardAppGroup = props.appGroupIdentifier;
    return infoConfig;
  });

  config = withEntitlementsPlist(config, (entitlementsConfig) => {
    const key = 'com.apple.security.application-groups';
    const current = entitlementsConfig.modResults[key] || [];
    entitlementsConfig.modResults[key] = [...new Set([...current, props.appGroupIdentifier])];
    return entitlementsConfig;
  });

  config = withXcodeProject(config, (projectConfig) => {
    copyExtensionFiles(
      projectConfig.modRequest.platformProjectRoot,
      props.appGroupIdentifier,
      displayName
    );
    addExtensionTarget(projectConfig.modResults, extensionBundleIdentifier, marketingVersion);
    return projectConfig;
  });

  return config;
}

module.exports = createRunOncePlugin(withKoltKeyboard, pkg.name, pkg.version);
