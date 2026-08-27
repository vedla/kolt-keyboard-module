const {
  createRunOncePlugin,
  withEntitlementsPlist,
  withInfoPlist,
  withXcodeProject,
} = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

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

function configureTargetBuildSettings(
  project,
  target,
  bundleIdentifier,
  marketingVersion,
  appDeveloperTeam
) {
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
    settings.DEVELOPMENT_TEAM = appDeveloperTeam;
    settings.MARKETING_VERSION = marketingVersion;
    settings.PRODUCT_BUNDLE_IDENTIFIER = `"${bundleIdentifier}"`;
    settings.PRODUCT_NAME = `"${TARGET_NAME}"`;
    settings.SKIP_INSTALL = 'YES';
    settings.SWIFT_VERSION = '5.0';
    settings.TARGETED_DEVICE_FAMILY = '"1,2"';
  }
}

function addExtensionTarget(project, bundleIdentifier, marketingVersion, appDeveloperTeam) {
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

  configureTargetBuildSettings(
    project,
    extensionTarget.target,
    bundleIdentifier,
    marketingVersion,
    appDeveloperTeam
  );
}

function copyExtensionFiles(projectRoot, appGroupIdentifier, displayName) {
  const destination = path.join(projectRoot, EXTENSION_DIRECTORY);
  // eslint-disable-next-line no-undef
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

function declareEasExtension(config, bundleIdentifier, appGroupIdentifier) {
  const eas = config.extra?.eas || {};
  const build = eas.build || {};
  const experimental = build.experimental || {};
  const ios = experimental.ios || {};
  const appExtensions = ios.appExtensions || [];
  const extension = {
    targetName: TARGET_NAME,
    bundleIdentifier,
    entitlements: {
      'com.apple.security.application-groups': [appGroupIdentifier],
    },
  };

  config.extra = {
    ...config.extra,
    eas: {
      ...eas,
      build: {
        ...build,
        experimental: {
          ...experimental,
          ios: {
            ...ios,
            appExtensions: [
              ...appExtensions.filter((item) => item.targetName !== TARGET_NAME),
              extension,
            ],
          },
        },
      },
    },
  };

  return config;
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
  const appDeveloperTeam = props.appleTeamId || config.ios?.appleTeamId;
  if (!appDeveloperTeam) {
    throw new Error(
      'kolt-keyboard requires an appDeveloperTeam to be specified in app.json or in the plugin props.'
    );
  }
  const displayName = props.displayName || 'Kolt Keyboard';
  const marketingVersion = config.version || '1.0.0';

  config = declareEasExtension(config, extensionBundleIdentifier, props.appGroupIdentifier);

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
    addExtensionTarget(
      projectConfig.modResults,
      extensionBundleIdentifier,
      marketingVersion,
      appDeveloperTeam
    );
    return projectConfig;
  });

  return config;
}

module.exports = createRunOncePlugin(withKoltKeyboard, pkg.name, pkg.version);
