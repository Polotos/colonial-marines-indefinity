import { useBackend, useLocalState } from '../backend';
import { Button, Dropdown, Section, Stack, ProgressBar, Box, Tabs } from '../components';
import { Window } from '../layouts';
import { CanvasLayer } from './CanvasLayer';
import { DrawnMap } from './DrawnMap';
import { ByondUi } from '../components';

interface TacMapProps {
  toolbarColorSelection: string;
  toolbarUpdatedSelection: string;
  updatedCanvas: boolean;
  themeId: number;
  svgData: any;
  canDraw: number;
  newCanvasFlatImage: string;
  oldCanvasFlatImage: string;
  exportedColor: string;
  mapFallback: string;
  mapRef: string;
  currentMenu: string;
  lastUpdateTime: any;
  canvasCooldownDuration: any;
  minimap_zlevels: any;
  canvasCooldown: any;
  exportedTacMapImage: any;
  selectedTheme: boolean;
}

const PAGES = [
  {
    title: 'Live Tacmap',
    canOpen: (data) => {
      return 1;
    },
    component: () => ViewMapPanel,
    icon: 'map',
    canAccess: (data) => {
      return data.canViewTacmap;
    },
  },
  {
    title: 'Map View',
    canOpen: (data) => {
      return 1;
    },
    component: () => OldMapPanel,
    icon: 'eye',
    canAccess: (data) => {
      return data.canViewCanvas;
    },
  },
  {
    title: 'Canvas',
    canOpen: (data) => {
      return !data.canvasCooldown;
    },
    component: () => DrawMapPanel,
    icon: 'paintbrush',
    canAccess: (data) => {
      return data.canDraw;
    },
  },
];

const colorOptions = [
  'black',
  'red',
  'orange',
  'blue',
  'purple',
  'green',
  'brown',
];

const colors: Record<string, string> = {
  'black': '#000000',
  'red': '#fc0000',
  'orange': '#f59a07',
  'blue': '#0561f5',
  'purple': '#c002fa',
  'green': '#02c245',
  'brown': '#5c351e',
};

export const TacticalMap = (props, context) => {
  const { data, act } = useBackend<TacMapProps>(context);
  const [pageIndex, setPageIndex] = useLocalState(context, 'pageIndex', 0);
  const PageComponent = PAGES[pageIndex].component();

  const handleTacmapOnClick = (i, pageTitle) => {
    setPageIndex(i);
    act('menuSelect', {
      selection: pageTitle,
    });
  };

  return (
    <Window
      width={700}
      height={850}
      theme={data.selectedTheme ? 'hive_status' : 'crtblue'}>
      <Window.Content>
        <Section
          fitted
          width="688px"
          fontSize="20px"
          textAlign="center"
          title="Tactical Map Options"
          justify="space-evenly">
          <Stack justify="center" align="center" fontSize="15px">
            <Stack.Item>
              <Tabs height="37.5px">
                {PAGES.map((page, i) => {
                  if (page.canAccess(data) === 0) {
                    return;
                  }
                  return (
                    <Tabs.Tab
                      key={i}
                      color={data.selectedTheme ? 'purple' : 'blue'}
                      selected={i === pageIndex}
                      disabled={page.canOpen(data) === 0}
                      icon={page.icon}
                      onClick={() => handleTacmapOnClick(i, page.title)}>
                      {page.canOpen(data) === 0 ? 'loading' : page.title}
                    </Tabs.Tab>
                  );
                })}
              </Tabs>
            </Stack.Item>
          </Stack>
        </Section>
        <PageComponent fitted />
      </Window.Content>
    </Window>
  );
};

const ViewMapPanel = (props, context) => {
  const { data } = useBackend<TacMapProps>(context);

  // byond ui can't resist trying to render
  if (data.mapRef === null) {
    return <OldMapPanel {...props} context={context} />;
  }

  return (
    <Section fitted height="86%">
      <ByondUi
        params={{
          id: data.mapRef,
          type: 'map',
          'background-color': 'none',
        }}
        class="TacticalMap"
      />
    </Section>
  );
};

const OldMapPanel = (props, context) => {
  const { data } = useBackend<TacMapProps>(context);
  return (
    <Section
      fitted
      height="86%"
      justify="center"
      align="center"
      fontSize="30px">
      <DrawnMap
        svgData={data.svgData}
        flatImage={data.oldCanvasFlatImage}
        backupImage={data.mapFallback}
      />
    </Section>
  );
};

const DrawMapPanel = (props, context) => {
  const { data, act } = useBackend<TacMapProps>(context);

  const timeLeftPct = data.canvasCooldown / data.canvasCooldownDuration;
  const canUpdate = data.canvasCooldown <= 0 && !data.updatedCanvas;

  const handleTacMapExport = (image: any) => {
    data.exportedTacMapImage = image;
  };

  const handleColorSelection = (dataSelection) => {
    if (colors[dataSelection] !== null && colors[dataSelection] !== undefined) {
      return colors[dataSelection];
    } else {
      return dataSelection;
    }
  };
  const findColorValue = (oldValue: string) => {
    return (Object.keys(colors) as Array<string>).find(
      (key) => colors[key] === (oldValue as string)
    );
  };

  return (
    <>
      <Section
        title="Canvas Options"
        className={'canvas-options'}
        width="688px">
        <Stack height="15px">
          <Stack.Item grow>
            {(!data.updatedCanvas && (
              <Button
                height="20px"
                fontSize="10px"
                fluid={1}
                disabled={!canUpdate}
                color="red"
                icon="download"
                className="text-center"
                content="Update Canvas"
                onClick={() => act('updateCanvas')}
              />
            )) || (
              <Button
                height="20px"
                fontSize="10px"
                fluid={1}
                color="green"
                icon="bullhorn"
                content="Announce"
                className="text-center"
                onClick={() =>
                  act('selectAnnouncement', {
                    image: data.exportedTacMapImage,
                  })
                }
              />
            )}
          </Stack.Item>
          <Stack.Item grow>
            <Button
              height="20px"
              fontSize="10px"
              fluid={1}
              color="grey"
              icon="trash"
              content="Clear Canvas"
              className="text-center"
              onClick={() => act('clearCanvas')}
            />
          </Stack.Item>
          <Stack.Item grow>
            <Button
              height="20px"
              fontSize="10px"
              fluid={1}
              color="grey"
              icon="recycle"
              content="Undo"
              className="text-center"
              onClick={() => act('undoChange')}
            />
          </Stack.Item>
          <Stack.Item grow>
            <Dropdown
              height="21px"
              noscroll={1}
              fluid={1}
              options={colorOptions}
              selected={data.toolbarColorSelection}
              color={data.toolbarColorSelection}
              onSelected={(value) => act('selectColor', { color: value })}
              displayText={data.toolbarColorSelection}
            />
          </Stack.Item>
        </Stack>
        <Stack
          className={'progress-stack'}
          position="absolute"
          width="98%"
          style={{ 'z-index': '1' }}
          bottom="-40px">
          <Stack.Item grow>
            {data.canvasCooldown > 0 && (
              <ProgressBar
                height="20px"
                value={timeLeftPct}
                backgroundColor="rgba(0, 0, 0, 0.5)"
                ranges={{
                  good: [-Infinity, 0.33],
                  average: [0.33, 0.67],
                  bad: [0.67, Infinity],
                }}>
                <Box textAlign="center" fontSize="15px" textColor="white">
                  {Math.ceil(data.canvasCooldown / 10)} seconds until the canvas
                  changes can be updated
                </Box>
              </ProgressBar>
            )}
          </Stack.Item>
        </Stack>
      </Section>
      <Section width="688px" justify="center" align="center" textAlign="center">
        <CanvasLayer
          selection={handleColorSelection(data.toolbarUpdatedSelection)}
          imageSrc={data.newCanvasFlatImage}
          key={data.lastUpdateTime}
          onImageExport={handleTacMapExport}
          onUndo={(value) =>
            act('selectColor', { color: findColorValue(value) })
          }
          onDraw={() => act('onDraw')}
        />
      </Section>
    </>
  );
};
