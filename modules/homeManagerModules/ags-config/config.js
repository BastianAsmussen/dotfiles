import GLib from "gi://GLib"

const main = "/tmp/ags/main.js"
const entry = `${App.configDir}/main.ts`
const bundler = GLib.getenv("AGS_BUNDLER") || "bun"

const v = {
    ags: pkg.version?.split(".").map(Number) || [],
    expect: [1, 8, 1],
}

const isVersionLess = (v1, v2) => {
    for (let i = 0; i < v2.length; i++) {
        if ((v1[i] || 0) < v2[i]) return true;
        if ((v1[i] || 0) > v2[i]) return false;
    }
    return false;
}

try {
    switch (bundler) {
        case "bun": await Utils.execAsync([
            "bun", "build", entry,
            "--outfile", main,
            "--external", "resource://*",
            "--external", "gi://*",
            "--external", "file://*",
        ]); break

        case "esbuild": await Utils.execAsync([
            "esbuild", "--bundle", entry,
            "--format=esm",
            `--outfile=${main}`,
            "--external:resource://*",
            "--external:gi://*",
            "--external:file://*",
        ]); break

        default:
            throw `"${bundler}" is not a valid bundler!`
    }

    if (isVersionLess(v.ags, v.expect)) {
        print(`My config needs at least v${v.expect.join(".")}, yours is v${v.ags.join(".")}!`)
        App.quit()
    }

    await import(`file://${main}`)
} catch (error) {
    console.error(error)
    App.quit()
}

export { }
