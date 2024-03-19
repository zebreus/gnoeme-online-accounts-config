import config from "./extractedConfig.json" with { type: "json" };
const { providers, descriptions, options } = config;

const groupedOptions = options.reduce((acc, option) => {
    const provider = (providers as string[]).find(provider => `src/goabackend/goa${provider.replace(/[-_ ]/g, "").toLowerCase()}provider.c` === option.file);
    const commonOption = provider ? false : (option.file == "src/daemon/goadaemon.c")


    if (!provider && !commonOption) {
        throw new Error(`No provider found for option ${JSON.stringify(option)}`);
    }
    const previous = acc.find(group => group.name === option.value);
    if (previous) {
        previous.providers = provider ? [...previous.providers, provider] : previous.providers;
        previous.commonOption = previous.commonOption || commonOption;
        return acc;
    }
    return [
        ...acc,
        {
            name: option.value,
            providers: provider ? [provider] : [],
            commonOption,
            type: option.type as "string" | "boolean"
        }
    ]
}, [] as { name: string, providers: string[], commonOption: boolean, type: "string" | "boolean" }[]);


const outputOptions = groupedOptions.map(option => {

    const matchingDescriptions = descriptions.filter(description => description.name === option.name).map(description => ({
        ...description,
        type: description.type === "s" ? "string" : description.type === "b" ? "boolean" : undefined
    }));

    const firstDescriptionAccess = matchingDescriptions[0]?.access;

    for (const description of matchingDescriptions) {
        if (description.type !== option.type) {
            throw new Error(`Type mismatch for option ${option.name}. \n Descriptions: ${JSON.stringify(matchingDescriptions)}`);
        }
        if (description.access !== firstDescriptionAccess) {
            throw new Error(`Access ${description.access} ${firstDescriptionAccess}mismatch between descriptions for option ${option.name}. \n Descriptions: ${JSON.stringify(matchingDescriptions)}`);
        }
    }

    return {
        name: option.name,
        type: option.type === "string" ? "string" : option.type === "boolean" ? "boolean" : undefined,
        descriptions: matchingDescriptions.map(description => description.description).filter(function (item, pos, self) {
            return self.indexOf(item) == pos;
        }),
        access: firstDescriptionAccess,
        providers: option.providers,
        commonOption: option.commonOption
    }
})

const singleObject = outputOptions.reduce((acc, option) => {
    acc[option.name] = {
        type: (option.type || undefined) as "string" | "boolean",
        descriptions: option.descriptions,
        access: (option.access || undefined) as "read" | "readwrite",
        providers: option.providers,
        commonOption: option.commonOption
    }
    return acc;

}, {} as Record<string, { type?: "string" | "boolean", descriptions: string[], access?: "read" | "readwrite", providers: string[], commonOption: boolean }>);

await Deno.writeTextFile("cleanedConfig.json", JSON.stringify(singleObject, null, 2));


type Option = { type?: "string" | "boolean", descriptions: string[], access?: "read" | "readwrite", providers: string[], commonOption?: boolean }

// Overrides for the 
// deno-lint-ignore no-explicit-any
const overrides: Record<string, "delete" | (Partial<Option & { default: boolean | string } & { required: boolean } & { extraDescription: string } & { description: string } & { example?: string }>)> = {
    // ForceRemove is only for templating I think
    "ForceRemove": "delete",
    // 
    "IsLocked": {
        //    extraDescriptions: "Set to true by default, because the file is read only",
        "default": true
    },
    "IsTemporary": {
        //   extraDescriptions: "Should never be set to true, because the file is read only",
        "default": false
    },
    "Identity": {
        // Description overwritten, because the original description is geared towards consumers
        description: `A string that uniquely identifies the account at the provider. This will only be displayed to the user if #org.gnome.OnlineAccounts.Account:PresentationIdentity is not set.

Note that this does not need to be unique across providers. For example, if the user is using the same
email-address for several providers
        `,
        required: true
    },
    "Provider": {
        description: `The type of the account. This value describes how data is accessed, e.g. what API
applications should use. Most other options are only relevant for a specific provider.`,
        required: true
    },
    "SessionId": {
        description: "The id of the temporary session if this account is temporary.",
    },
    "AcceptSslErrors": {
        extraDescription: `This setting is only used by the exchange and owncloud providers.Use the more specific settings for the other providers.`,
    },
    "CalendarEnabled": {
        description: `If true, the account will not expose any
#org.gnome.OnlineAccounts.Calendar interface.If the account does not
provide calendar- like capabilities, this property does nothing.`,
        "commonOption": true
    },
    "ContactsEnabled": {
        description: `If true, the account will not expose any
#org.gnome.OnlineAccounts.Contacts interface.If the account does not
provide contacts - like capabilities, this property does nothing.`,
        "commonOption": true
    },
    "MailEnabled": {
        description: `If true, the account will not expose any
#org.gnome.OnlineAccounts.Mail interface.If the account does not
provide email - like messaging capabilities, this property does
nothing.

If the account uses IMAP / SMTP you also need to set the
\`Enabled\` option to the same value.`,
        "commonOption": true
    },
    "Host": {
        "description": `The Exchange server to use. This is always a domain name.
Use this to determine the <ulink url="https://learn.microsoft.com/en-us/exchange/client-developer/exchange-web-services/autodiscover-for-exchange">Autodiscover</ulink> service endpoints.
      
eg. if \`Host\` is <literal>bar.com</literal>, then the possible endpoints are
<literal>https://bar.com/autodiscover/autodiscover.xml</literal> and
<literal>https://autodiscover.bar.com/autodiscover/autodiscover.xml</literal>.`,
    },
    "TicketingEnabled": {
        "description": `If true, the account will not expose any
#org.gnome.OnlineAccounts.Ticketing interface. If the account does not
provide ticketing-like capabilities, this property does nothing.`,
        "commonOption": true
    },
    "PreauthenticationSource": {
        "description": "A preauthentication source used by pkinit (such as PKCS11:libcoolkeypk11.so) for Kerberos",
    },
    "FilesEnabled": {
        "description": `If true, the account will not expose any
#org.gnome.OnlineAccounts.Files interface. If the account does not
provide files-like capabilities, this property does nothing.`,
        "commonOption": true
    },
    "PhotosEnabled": {
        "description": `If true, the account will not expose any
#org.gnome.OnlineAccounts.Photos interface. If the account does not
provide photos-like capabilities, this property does nothing.`,
        "commonOption": true
    },
    "PrintersEnabled": {
        "description": `If true, the account will not expose any
#org.gnome.OnlineAccounts.Printers interface. If the account does not
provide printers-like capabilities, this property does nothing.`,
        "commonOption": true
    },
    // TODO: Add Aliases with ImapEnabled and SmtpEnabled
    "Enabled": {
        "description": `Enable IMAP and SMTP for the account. You should set
      \`MailEnabled\` to the same value.`,
    },
    "MusicEnabled": {
        description: `If true, the account will not expose any
 #org.gnome.OnlineAccounts.Music interface. If the account does not
 provide music-like capabilities, this property does nothing.`,
        "commonOption": true
    },
    "Uri": {
        "description": "URI of the nextcloud server to use.",
        "example": '"https://cloud.example.com"'
    }
}

for (const [optionName, override] of Object.entries(overrides)) {
    if (override === "delete") {
        continue;
    }

    if (singleObject[optionName] === undefined) {
        throw new Error(`Overrides contain a override for option ${optionName} which was not detected in the extractedConfig. Please have a look and fix this.`);
    }
}

type FixedOption = {
    type: "string" | "boolean" | string[], required: boolean | undefined, example: string | undefined, default: undefined | string | boolean, description: string, providers: string[], commonOption?: boolean
}

const basekey = "service.gnome-online-accounts.accounts._name_";

const cleanupDescription = (description: string) => {
    // [home.activation](#opt-home.activation).
    const replacedDescription = description
        .replace(/%TRUE/g, "`true`")
        .replace(/%FALSE/g, "`false`")
        .replace(/"true"/g, "`true`")
        .replace(/"IsTemporary"/g, `[](#opt-${basekey}.IsTemporary)`)
        .replace(/<ulink url="([^"]+)">([^<]+)<\/ulink>/g, "[$2]($1)")
        .replace(/<literal>([^<]+)<\/literal>/g, "`$1`")
        .replace(/<filename>([^<]+)<\/filename>/g, "`$1`")
        .replace(/#(org.gnome.OnlineAccounts.Account:Id)([ .]|$)/g, `[](#opt-${basekey})$2`)
        .replace(/#(org.gnome.OnlineAccounts.[A-Z][A-Za-z]+:([A-Z][A-Za-z]+))/g, `[](#opt-${basekey}.$2)`)
        .replace(/#(org.gnome.OnlineAccounts.([A-Z][A-Za-z]+))([\s\.]|$)(?![:])/g, "[$1](https://developer-old.gnome.org/goa/stable/gdbus-$1.html)$3")

    // .replace(/#(org.gnome.OnlineAccounts.Files)/g, "[$1](https://developer-old.gnome.org/goa/stable/gdbus-$1.html)")

    return replacedDescription;
}

const fixedOptions = Object.entries(singleObject).reduce((acc, [optionName, option]) => {
    const override = overrides[optionName] ?? {};
    if (override === "delete") {
        return acc;
    }

    const type = optionName === "Provider" ? (providers as string[]) : (override.type || option.type || "string" as const) as "string" | "boolean"

    if (option.descriptions.length > 1 && !override.description) {
        throw new Error(`Multiple descriptions for option ${optionName}. Details below. Create an override with the correct description or adjust this code.
Option ${optionName}: ${JSON.stringify(option, null, 2)}
Override: ${JSON.stringify(override, null, 2)}`);
    }
    let mainDescription = override.description ? override.description : option.descriptions[0];
    if (!mainDescription) {
        throw new Error(`No description for option ${optionName}. Create an override with the correct description or adjust this code.
Option ${optionName}: ${JSON.stringify(option, null, 2)}
Override: ${JSON.stringify(override, null, 2)}`);
    }

    const relevantProvidersDescription = option.commonOption ? "Relevant for all accounts." : option.providers?.length ? `Relevant for accounts using the ${[option.providers.slice(0, -1).join(", "), option.providers.slice(-1)].filter(v => v).join(", or ")} provider.` : "";
    const description = cleanupDescription([mainDescription, override.extraDescription, relevantProvidersDescription].filter(v => v).join("\n\n"));
    const fixedOption: FixedOption = {
        type: optionName === "Provider" ? (providers as string[]) : (override.type || option.type || "string" as const) as "string" | "boolean",
        example: override.example ?? undefined,
        default: override.default ?? undefined,
        required: override.required ?? false,
        description: description,
        providers: override.providers ?? option.providers,
        commonOption: override.commonOption ?? option.commonOption ?? false,
    }
    return {
        ...acc,
        [optionName]: fixedOption
    }
}, {} as Record<string, FixedOption>)

await Deno.writeTextFile("fixedConfig.json", JSON.stringify(fixedOptions, null, 2));

let optionModules = Object.entries(fixedOptions).map(([optionName, option]) => {
    const type = `${option.required ? "" : "types.nullOr "}${option.type === "string" ? "types.str" : option.type === "boolean" ? "types.bool" : `(types.enum [${(option.type.map(provider => `"${provider}"`)).join(" ")}])`}`;
    const defaultValue = option.default ? (option.default.toString()) : option.required ? undefined : "null";
    const example = option.example ? option.example : undefined;

    const entry = `${optionName} = mkOption {
type = ${type};${defaultValue ? `
default = ${defaultValue};` : ""}${example ? `
example = ${example};` : ""}${option.description ? `
description = ''
${option.description}
'';` : ""}
};`;
    return entry;
})

let nixString = `
# This file is generated from the source of gnome-online-accounts
# using https://github.com/zebreus/gnome-online-accounts-config
# Do not edit this file manually.

{ lib, ... }:
with lib;
let
  accountType = { lib, ... }: with lib; {
    freeformType = with lib.types; attrsOf (oneOf [ null str bool ]);

    options = {
      ${optionModules.join("\n  ")}
    };
  };
in
{
  options = with lib ; {
    services.gnome-online-accounts.accounts = mkOption {
      type = types.attrsOf (types.submodule accountType);
      description = ''
      Accounts which are put into \`.config/goa-1.0/accounts.conf\`. The keys are put directly into the config file. Every account needs to have a [](#opt-service.gnome-online-accounts.accounts._name_.Provider) and unique [](#opt-service.gnome-online-accounts.accounts._name_).

      All valid settings for ${Deno.env.get("version") ? `gnome-online-accounts ${Deno.env.get("version")}` : "the latest gnome-online-accounts version"} are covered by this module.

      This module is based on the source code of gnome-online-accounts, as there is no documentation for the settings in accounts.conf.
      '';
    };
  };
}
`;

await Deno.writeTextFile("fixedConfig.nix", nixString);
