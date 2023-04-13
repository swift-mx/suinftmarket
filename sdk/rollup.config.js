import typescript from '@rollup/plugin-typescript';

var rollup_config = [
  {
    input: 'src/index.ts',
    output: [
      {
        file: './dist/index.js',
        format: 'cjs',
        sourcemap: true
      },
      {
        file: './dist/index.mjs',
        format: 'es',
        sourcemap: true
      }
    ],
    external: ['@mysten/sui.js', 'commander', 'fs', 'yaml', 'decimal.js'],
    plugins: [typescript()]
  }
];
export { rollup_config as default };
