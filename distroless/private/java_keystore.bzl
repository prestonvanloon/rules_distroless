"jks"

load(":tar.bzl", "tar_lib")

_DOC = """Create a java keystore (database) of cryptographic keys, X.509 certificate chains, and trusted certificates.

Currently only public  X.509 are supported as part of the PUBLIC API contract.
"""

def _java_keystore_impl(ctx):
    jks = ctx.actions.declare_file(ctx.attr.name + ".jks")

    args = ctx.actions.args()
    args.add(jks)
    args.add_all(ctx.files.certificates)

    ctx.actions.run(
        executable = ctx.executable._java_keystore,
        inputs = ctx.files.certificates,
        outputs = [jks],
        arguments = [args],
    )

    output = ctx.actions.declare_file(ctx.attr.name + ".tar.gz")
    mtree = tar_lib.create_mtree(ctx)
    mtree.add_file_with_parents("/etc/ssl/certs/java/cacerts", jks)
    mtree.build(output = output, mnemonic = "JavaKeyStore", inputs = [jks])

    return [
        DefaultInfo(files = depset([output])),
        OutputGroupInfo(
            jks = depset([jks]),
        ),
    ]

java_keystore = rule(
    doc = _DOC,
    attrs = {
        "_java_keystore": attr.label(
            executable = True,
            cfg = "exec",
            default = ":keystore_binary",
        ),
        "certificates": attr.label_list(
            allow_files = True,
            mandatory = True,
            allow_empty = False,
        ),
    },
    implementation = _java_keystore_impl,
    toolchains = [
        tar_lib.TOOLCHAIN_TYPE,
    ],
)
